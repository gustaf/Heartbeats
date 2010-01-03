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


/* --- Data --- */
/// The application key is specific to each project, and allows Spotify
/// to produce statistics on how our service is used.
extern const uint8_t g_appkey[];
/// The size of the application key.
extern const size_t g_appkey_size;

/// A handle to the main thread, needed for synchronization between callbacks
/// and the main loop.
static pthread_t g_main_thread = -1;

/// The global session handle
static sp_session *g_sess;
/// The global playlistcontainer handle
static sp_playlistcontainer *g_pc;

/// State variables
static int g_logged_in = 0;
static int g_playlists_loaded_after_log_in = 0;
const char *g_uri;

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
	sp_playlistcontainer *pc = sp_session_playlistcontainer(sess);
	int i;

	if (SP_ERROR_OK != error) {
		syslog(LOG_ERR, "Login failed: %s\n", sp_error_message(error));
		exit(2);
	}

	// Let us print the nice message...
	sp_user *me = sp_session_user(sess);
	const char *my_name = (sp_user_is_loaded(me) ?
		sp_user_display_name(me) :
		sp_user_canonical_name(me));

	for (i = 0; i < sp_playlistcontainer_num_playlists(pc); ++i) {
		sp_playlist *pl = sp_playlistcontainer_playlist(pc, i);

	}

	g_logged_in = 1;

	sp_link *link = sp_link_create_from_string(g_uri);
	sp_playlistcontainer_add_playlist(g_pc, link);

	//fflush(stdout);
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
	pthread_kill(g_main_thread, SIGIO);
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

/**
 * Print the given track title together with some trivial metadata
 *
 * @param  track   The track object
 */
static void print_track(sp_track *track)
{
	int duration = sp_track_duration(track);

	printf("Track \"%s\" [%d:%02d] has %d artist(s), %d%% popularity\n",
	       sp_track_name(track),
	       duration / 60000,
	       (duration / 1000) / 60,
	       sp_track_num_artists(track),
	       sp_track_popularity(track));

	int i;
	sp_artist *artist;
	for(i = 0; i < sp_track_num_artists(track); i++)
	{
		artist = sp_track_artist(track, i);
		if(!sp_artist_is_loaded(artist)) continue;
		printf(" %s,", sp_artist_name(artist));
	}
	printf("\n");
}

static void print_playlist(sp_playlist *pl)
{
	sp_link *link = sp_link_create_from_playlist(pl);
	char uri[256];
	sp_link_as_string(link, uri, 256);
	printf("name [%s] uri [%s]\n", sp_playlist_name(pl), uri);
	int i;
	sp_track *track;
	for(i = 0; i < sp_playlist_num_tracks(pl); i++)
	{
		track = sp_playlist_track(pl, i);
		if(!sp_track_is_loaded(track)) continue;
		print_track(track);
	}
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

	int i;
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
			if(strcmp(g_uri, uri) == 0)
			{
				print_playlist(pl);
				exit(1);
			}
		}
	}
}

/**
 * The main loop. When this function returns, the program should terminate.
 *
 * To avoid having the \p SIGIO in notify_main_thread() interrupt libspotify,
 * we block it while processing events.
 *
 * @sa sp_session_process_events
 */
static void loop()
{
	sigset_t sigset;

	sigemptyset(&sigset);
	sigaddset(&sigset, SIGIO);

	while (1) {
		int timeout = -1;

		pthread_sigmask(SIG_BLOCK, &sigset, NULL);
		sp_session_process_events(g_sess, &timeout);
		if(g_logged_in) session_ready();
		pthread_sigmask(SIG_UNBLOCK, &sigset, NULL);
		usleep(timeout * 1000);
	}
}

/**
 * A dummy function to ignore SIGIO.
 */
static void sigIgn(int signo)
{
}

int main(int argc, char **argv)
{
	sp_session *sp;
	sp_error err;
	const char *username = NULL;
	const char *password = NULL;
	
	// Sending passwords on the command line is bad in general.
	// We do it here for brevity.
	if (argc < 4 || argv[1][0] == '-') {
		//fprintf(stderr, "usage: %s <username> <password> <playlist uri>\n",
		 //               basename(argv[0]));
		exit(1);
	}
	username = argv[1];
	password = argv[2];
	g_uri = argv[3];

	// Setup for waking up the main thread in notify_main_thread()
	g_main_thread = pthread_self();
	signal(SIGIO, &sigIgn);

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

	loop();

	return 0;
}
