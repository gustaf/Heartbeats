#include <errno.h>
#include <libgen.h>
#include <signal.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <spotify/api.h>
#include <syslog.h>
#include "fcgiapp.h"
#include "simclist.h"


/* --- Data --- */
/// The application key is specific to each project, and allows Spotify
/// to produce statistics on how our service is used.
extern const uint8_t g_appkey[];
/// The size of the application key.
extern const size_t g_appkey_size;

/// The global session handle
static sp_session *g_sess;
/// The global playlistcontainer handle
static sp_playlistcontainer *g_pc;

/// State variables
static int g_logged_in = 0;
static int g_playlists_loaded_after_log_in = 0;
static int g_notified = 0;

static list_t g_in_list;
static list_t g_out_list;
static pthread_mutex_t g_in_list_mutex = PTHREAD_MUTEX_INITIALIZER;

/* --------------------  PLAYLIST CONTAINER CALLBACKS  --------------------- */
/**
 * Callback from libspotify, telling us a playlist was added to the playlist container.
 *
 * We add our playlist callbacks to the newly added playlist.
 *
 * @param  pc            The playlist container handle
 * @param  pl            The playlist handle
 * @param  position      Index of the added playlist
 * @param  userdata      The opaque pointer
 */
static void playlist_added(sp_playlistcontainer *pc, sp_playlist *pl,
                           int position, void *userdata)
{
}

/**
 * Callback from libspotify, telling us a playlist was removed from the playlist container.
 *
 * This is the place to remove our playlist callbacks.
 *
 * @param  pc            The playlist container handle
 * @param  pl            The playlist handle
 * @param  position      Index of the removed playlist
 * @param  userdata      The opaque pointer
 */
static void playlist_removed(sp_playlistcontainer *pc, sp_playlist *pl,
		int position, void *userdata)
{
}

/**
 * The playlist container callbacks
 */
static sp_playlistcontainer_callbacks pc_callbacks = {
	.playlist_added = &playlist_added,
	.playlist_removed = &playlist_removed,
};


/* ---------------------------  SESSION CALLBACKS  ------------------------- */
/**
 * This callback is called when an attempt to login has succeeded or failed.
 *
 * @sa sp_session_callbacks#logged_in
 */
static void logged_in(sp_session *sess, sp_error error)
{
	if (SP_ERROR_OK != error) {
		syslog(LOG_ERR, "Login failed: %s\n", sp_error_message(error));
		exit(2);
	}

	g_logged_in = 1;
}

/**
 * This callback is called from an internal libspotify thread to ask us to
 * reiterate the main loop.
 *
 * We notify the main thread using a condition variable and a protected variable.
 *
 * @sa sp_session_callbacks#notify_main_thread
 */
static void notify_main_thread(sp_session *sess)
{
	g_notified = 1;
}

/**
 * Callback called when libspotify has new metadata available
 *
 * Not used in this example (but available to be able to reuse the session.c file
 * for other examples.)
 *
 * @sa sp_session_callbacks#metadata_updated
 */
static void metadata_updated(sp_session *sess)
{
}

/**
 * The session callbacks
 */
static sp_session_callbacks session_callbacks = {
	.logged_in = &logged_in,
	.notify_main_thread = &notify_main_thread,
	//.music_delivery = &music_delivery,
	.metadata_updated = &metadata_updated,
	//.play_token_lost = &play_token_lost,
	.log_message = NULL,
	//.end_of_track = &end_of_track,
};

/**
 * The session configuration. Note that application_key_size is an external, so
 * we set it in main() instead.
 */
static sp_session_config spconfig = {
	.api_version = SPOTIFY_API_VERSION,
	.cache_location = "tmp",
	.settings_location = "tmp",
	.application_key = g_appkey,
	.application_key_size = 0, // Set in main()
	.user_agent = "heartb.com playlist lookup",
	.callbacks = &session_callbacks,
	NULL,
};
/* -------------------------  END SESSION CALLBACKS  ----------------------- */

/* -------------------------        XML CREATION     ----------------------- */
static void xml_escape(const char *in, char **out)
{
	int extra_space = 0;
	int i;
	for(i = 0; i < strlen(in); i++) {
		switch (in[i]) {
			case '\"':
			case '\'':
				extra_space += 5;
				break;
			case '<':
			case '>':
				extra_space += 3;
				break;
			case '&':
				extra_space += 4;
				break;
		}
	}
	*out = malloc(strlen(in) + extra_space + 1);
	strcpy(*out, "");
	for(i = 0; i < strlen(in); i++) {
		switch (in[i]) {
			case '\"':
				strcat(*out, "&quot;");
				break;
			case '\'':
				strcat(*out, "&apos;");
				break;
			case '<':
				strcat(*out, "&lt;");
				break;
			case '>':
				strcat(*out, "&gt;");
				break;
			case '&':
				strcat(*out, "&amp;");
				break;
			default:
				sprintf(*out, "%s%c", *out, in[i]);
				break;
		}
	}
}

static void artist_as_xml(sp_artist *artist, char **xml)
{
	char *template = "<artist>%s</artist>";
	char *data;
	xml_escape(sp_artist_name(artist), &data);
	int l = strlen(template) + strlen(data) + 1;
	*xml = malloc(l);
	if(*xml == NULL) syslog(LOG_ERR, "could not malloc");
	sprintf(*xml, template, data);
	free(data);
}

static void track_as_xml(sp_track *track, char **xml)
{
	char *template = "<track name=\"%s\" popularity=\"%d\" album=\"%s\" uri=\"%s\" duration=\"%d\">%s</track>";
	char *name, *album;
	xml_escape(sp_track_name(track), &name);
	xml_escape(sp_album_name(sp_track_album(track)), &album);
	int pop = sp_track_popularity(track);
	int duration = sp_track_duration(track);
	char uri[256];
	sp_link *link = sp_link_create_from_track(track, 0);
	sp_link_as_string(link, uri, 256);

	int i;
	sp_artist *artist;
	char *xml_artists = malloc(1);
	strcpy(xml_artists, "");
	char *xml_artist;
	for(i = 0; i < sp_track_num_artists(track); i++)
	{
		artist = sp_track_artist(track, i);
		artist_as_xml(artist, &xml_artist);
		xml_artists = realloc(xml_artists, strlen(xml_artists) + strlen(xml_artist) + 1);
		if(xml_artists == NULL) syslog(LOG_ERR, "could not realloc");
		strcat(xml_artists, xml_artist);
		free(xml_artist);
	}

	int l = strlen(template) + strlen(name) + 2 + strlen(album) + strlen(uri) + 20 + strlen(xml_artists) + 1;
	*xml = malloc(l);
	if(*xml == NULL) syslog(LOG_ERR, "could not malloc");
	sprintf(*xml, template, name, pop, album, uri, duration, xml_artists);
	free(xml_artists);
	free(name);
	free(album);
}

static void playlist_as_xml(sp_playlist *pl, char** xml)
{
	char *template = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<playlist name=\"%s\" uri=\"%s\" collaborative=\"%s\">%s</playlist>";
	char *name;
	xml_escape(sp_playlist_name(pl), &name);
	sp_link *link = sp_link_create_from_playlist(pl);
	char uri[256];
	sp_link_as_string(link, uri, 256);
	char *uri_clean;
	xml_escape(uri, &uri_clean);
	char collab[4];
	if(sp_playlist_is_collaborative(pl)) sprintf(collab, "yes");
	else sprintf(collab, "no");

	int i;
	sp_track *track;
	char *xml_tracks = malloc(1);
	strcpy(xml_tracks, "");
	char *xml_track;
	for(i = 0; i < sp_playlist_num_tracks(pl); i++)
	{
		track = sp_playlist_track(pl, i);
		track_as_xml(track, &xml_track);
		xml_tracks = realloc(xml_tracks, strlen(xml_tracks) + strlen(xml_track) + 1);
		if(xml_tracks == NULL) syslog(LOG_ERR, "could not realloc");
		strcat(xml_tracks, xml_track);
		free(xml_track);
	}

	int l = strlen(template) + strlen(name) + strlen(uri) + 3 + strlen(xml_tracks) + 1;
	*xml = malloc(l);
	if(*xml == NULL) syslog(LOG_ERR, "could not malloc");
	sprintf(*xml, template, name, uri, collab, xml_tracks);
	free(xml_tracks);
	free(name);
	free(uri_clean);
}
/* ------------------------- END XML CREATION ----------------------------*/

static void post_playlist(sp_playlist *pl)
{
	char *xml;
	playlist_as_xml(pl, &xml);
	syslog(LOG_INFO, "playlist as xml: %s", xml);
	char *template = "wget -q -O - --post-data='%s' http://heartb.com/playlist_receiver > /dev/null";
	char *command = malloc(strlen(template) + strlen(xml) + 1);
	if(command == NULL) syslog(LOG_ERR, "could not malloc");
	sprintf(command, template, xml);
	int rv = system(command);
	if(rv != 0) syslog(LOG_ERR, "Posted XML, got return code: %d", rv);
	else syslog(LOG_INFO, "Posted XML successfully");
	free(xml);
	free(command);
}

static bool playlist_is_loaded(sp_playlist *pl)
{
	if(!sp_playlist_is_loaded(pl)) return 0;

	int i;
	int j;
	sp_track *track;
	sp_artist *artist;
	for(i = 0; i < sp_playlist_num_tracks(pl); i++)
	{
		track = sp_playlist_track(pl, i);
		if(!sp_track_is_loaded(track)) return 0;
		for(j = 0; j < sp_track_num_artists(track); j++)
		{
			artist = sp_track_artist(track, j);
			if(!sp_artist_is_loaded(artist)) return 0;
		}
	}

	return 1;
}

static void session_ready()
{
	int num_playlists = sp_playlistcontainer_num_playlists(g_pc);
	if(num_playlists > 0) g_playlists_loaded_after_log_in = 1;

	int i, uri_pos;
	sp_playlist *pl;
	sp_link *link;
	char uri[256];
	for(i = 0; i < num_playlists; i++)
	{
		pl = sp_playlistcontainer_playlist(g_pc, i);
		if(playlist_is_loaded(pl))
		{
			link = sp_link_create_from_playlist(pl);
			sp_link_as_string(link, uri, 256);
			uri_pos = list_locate(&g_out_list, uri);
			if(uri_pos >= 0) {
				list_delete_at(&g_out_list, uri_pos);
				post_playlist(pl);
				sp_playlistcontainer_remove_playlist(g_pc, i);
				syslog(LOG_INFO, "removing playlist: %s", uri);
			}
		}
	}
	
	pthread_mutex_lock(&g_in_list_mutex);
	char *incoming_uri = list_fetch(&g_in_list);
	pthread_mutex_unlock(&g_in_list_mutex);
	if(incoming_uri != NULL) {
		link = sp_link_create_from_string(incoming_uri);
		if(link != NULL) {
			if(NULL != sp_playlistcontainer_add_playlist(g_pc, link))
				list_append(&g_out_list, incoming_uri);
		}
	}
}

static void loop()
{
	const int frame_duration = 10000;
	int timeout = -1;
	int frame_count = 0;
	while (1) {
		if(g_notified || timeout < frame_duration * frame_count) {
			sp_session_process_events(g_sess, &timeout);
			timeout *= 1000;
			frame_count = 0;
			g_notified = 0;
		}
		if(g_logged_in) session_ready();
		usleep(frame_duration);
		frame_count++;
	}
}

static char* stripped_req_uri(char *in)
{
    char *prefix = "/playlist/";
    if(strstr(in, prefix) != NULL) return in + strlen(prefix);
    return NULL;
}

static void *fcgi_loop()
{
	FCGX_Stream *in, *out, *err;
	FCGX_ParamArray envp;
	char *req_uri;

	while (FCGX_Accept(&in, &out, &err, &envp) >= 0) {
		FCGX_FPrintF(out,"Content-type: text/plain\r\n\r\nok");
		req_uri = FCGX_GetParam("REQUEST_URI", envp);
		if(req_uri == NULL) continue;
		req_uri = stripped_req_uri(req_uri);
		if(req_uri == NULL) continue;
		syslog(LOG_INFO, "Received uri: %s", req_uri);
		pthread_mutex_lock(&g_in_list_mutex);
		list_append(&g_in_list, req_uri);
		pthread_mutex_unlock(&g_in_list_mutex);
	}
	return 0;
}

int main(void)
{
	list_init(&g_in_list);
	list_init(&g_out_list);
	list_attributes_copy(&g_in_list, list_meter_string, 1);
	list_attributes_copy(&g_out_list, list_meter_string, 1);
	list_attributes_comparator(&g_out_list, list_comparator_string);

	sp_session *sp;
	sp_error err;
	const char *username = "kallus";
	const char *password = "pagedown";

	/* Create session */
	spconfig.application_key_size = g_appkey_size;

	err = sp_session_init(&spconfig, &sp);

	if (SP_ERROR_OK != err) {
		syslog(LOG_ERR, "Unable to create session: %s\n", sp_error_message(err));
		exit(1);
	}

	g_sess = sp;

	g_pc = sp_session_playlistcontainer(g_sess);

	sp_playlistcontainer_add_callbacks(
		sp_session_playlistcontainer(g_sess),
		&pc_callbacks,
		NULL);

	sp_session_login(sp, username, password);

	//start fcgi thread
	pthread_t fcgi_thread;
	pthread_create(&fcgi_thread, NULL, fcgi_loop, NULL);

	loop();

	return 0;
}
