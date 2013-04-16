/*
Copyright (C) 1997-2001 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
// Main windowed and fullscreen graphics interface module. This module
// is used for both the software and OpenGL rendering versions of the
// Quake refresh engine.

#include <assert.h>
#include <dlfcn.h> // ELF dl loader
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>

#include "../client/client.h"

#include "../linux/rw_linux.h"

// Structure containing functions exported from refresh DLL
//refexport_t	re;

// Console variables that we need to access from this module
cvar_t		*vid_gamma;
cvar_t		*vid_ref;			// Name of Refresh DLL loaded
cvar_t		*vid_xpos;			// X coordinate of window position
cvar_t		*vid_ypos;			// Y coordinate of window position
cvar_t		*vid_fullscreen;
cvar_t		*r_customwidth;
cvar_t		*r_customheight;

// Global variables used internally by this module
viddef_t	viddef;				// global video state; used by other modules
void		*reflib_library;		// Handle to refresh DLL 
qboolean	reflib_active = false;


#define VID_NUM_MODES ( sizeof( vid_modes ) / sizeof( vid_modes[0] ) )

// Miscellaneous GL Driver crud

#define FALLBACK_DRIVER_COUNT 3
extern const char so_file[];// = "/etc/quake2.conf";
char *opengl_drivers[FALLBACK_DRIVER_COUNT] = {  "libGL", "libGL.so", "libGL.so.1" };
char * gl_string;

/** KEYBOARD **************************************************************/

void Do_Key_Event(int key, qboolean down);

void (*KBD_Update_fp)(void);
void (*KBD_Init_fp)(Key_Event_fp_t fp);
void (*KBD_Close_fp)(void);

/** MOUSE *****************************************************************/

static in_state_t n_state;

void (*RW_IN_Init_fp)(in_state_t *in_state_p);
void (*RW_IN_Shutdown_fp)(void);
void (*RW_IN_Activate_fp)(qboolean active);
void (*RW_IN_Commands_fp)(void);
void (*RW_IN_Move_fp)(usercmd_t *cmd);
void (*RW_IN_Frame_fp)(void);

void RW_IN_Init (void);
void RW_IN_Shutdown (void);
void RW_IN_Activate (qboolean active);
void RW_IN_Commands (void);
void RW_IN_Move (usercmd_t *cmd);
void RW_IN_Frame(void);




/*
  ==========================================================================

DLL GLUE

==========================================================================
*/

#define	MAXPRINTMSG	4096
void VID_Printf (int print_level, char *fmt, ...)
{
	va_list		argptr;
	char		msg[MAXPRINTMSG];
	
	va_start (argptr,fmt);
	vsprintf (msg,fmt,argptr);
	va_end (argptr);

	if (print_level == PRINT_ALL)
		Com_Printf ("%s", msg);
	else
		Com_DPrintf ("%s", msg);
}

void VID_Error (int err_level, char *fmt, ...)
{
	va_list		argptr;
	char		msg[MAXPRINTMSG];
	
	va_start (argptr,fmt);
	vsprintf (msg,fmt,argptr);
	va_end (argptr);

	Com_Error (err_level,"%s", msg);
}

//==========================================================================

/*
============
VID_Restart_f

Console command to re-start the video mode and refresh DLL. We do this
simply by setting the modified flag for the vid_ref variable, which will
cause the entire video mode and refresh DLL to be reset on the next frame.
============
*/
void VID_Restart_f (void)
{
	vid_ref->modified = true;
}

/*
** VID_GetModeInfo
*/
typedef struct vidmode_s
{
	const char *description;
	int         width, height;
	int         mode;
} vidmode_t;

vidmode_t vid_modes[] =
{
	// Make sure you update ui_video.c if this changes

        { "Mode 0: 320x240",    320, 240,   0 },
        { "Mode 1: 400x300",    400, 300,   1 },
        { "Mode 2: 512x384",    512, 384,   2 },
        { "Mode 3: 640x480",    640, 480,   3 },
        { "Mode 4: 800x600",    800, 600,   4 },
        { "Mode 5: 960x720",    960, 720,   5 },
        { "Mode 6: 1024x768",   1024, 768,  6 },
        { "Mode 7: 1152x864",   1152, 864,  7 },
        { "Mode 8: 1280x960",   1280, 960,  8 },
        { "Mode 9: 1280x1024",  1280, 1024, 9 },
        { "Mode 10: 1400x1050", 1400, 1050, 10 },
        { "Mode 11: 1600x1200", 1600, 1200, 11 },
        { "Mode 12: 1920x1440", 1920, 1440, 12 },
        { "Mode 13: 2048x1536", 2048, 1536, 13 },
        { "Mode 14: 800x480",   800,  480,  14 },
        { "Mode 15: 856x480",   856,  480,  15 },
        { "Mode 16: 1024x600",  1024, 600,  16 },
        { "Mode 17: 1280x720",  1280, 720,  17 },
        { "Mode 18: 1280x768",  1280, 768,  18 },
        { "Mode 19: 1280x800",  1280, 800,  19 },
        { "Mode 20: 1360x768",  1360, 768,  20 },
        { "Mode 21: 1366x768",  1366, 768,  21 },
        { "Mode 22: 1440x900",  1440, 900,  22 },
        { "Mode 23: 1600x900",  1600, 900,  23 },
        { "Mode 24: 1600x1024", 1600, 1024, 24 },
        { "Mode 25: 1680x1050", 1680, 1050, 25 },
        { "Mode 26: 1920x1080", 1920, 1080, 26 },
        { "Mode 27: 1920x1200", 1920, 1200, 27 },
        { "Mode 28: 2560x1080", 2560, 1080, 28 },
        { "Mode 29: 2560x1440", 2560, 1440, 29 },
        { "Mode 30: 2560x1600", 2560, 1600, 30 }

};

qboolean VID_GetModeInfo( int *width, int *height, int mode )
{
	if (mode == -1) // custom mode
	{
		*width  = r_customwidth->value;
		*height = r_customheight->value;
		return true;
	}

	if ( mode < 0 || mode >= VID_NUM_MODES )
		return false;

	*width  = vid_modes[mode].width;
	*height = vid_modes[mode].height;

	return true;
}

/*
** VID_NewWindow
*/
void VID_NewWindow ( int width, int height)
{
	viddef.width  = width;
	viddef.height = height;
}

void VID_FreeReflib (void)
{
	if (reflib_library) {
		if (KBD_Close_fp)
			KBD_Close_fp();
		if (RW_IN_Shutdown_fp)
			RW_IN_Shutdown_fp();
		dlclose(reflib_library);
	}

	KBD_Init_fp = NULL;
	KBD_Update_fp = NULL;
	KBD_Close_fp = NULL;
	RW_IN_Init_fp = NULL;
	RW_IN_Shutdown_fp = NULL;
	RW_IN_Activate_fp = NULL;
	RW_IN_Commands_fp = NULL;
	RW_IN_Move_fp = NULL;
	RW_IN_Frame_fp = NULL;

	//memset (&re, 0, sizeof(re));
	reflib_library = NULL;
	reflib_active  = false;
}


/*
==============
VID_LoadRefresh
==============
*/

qboolean VID_LoadRefresh( char *name )
{
	//refimport_t	ri;
	//GetRefAPI_t	GetRefAPI;
	char	fn[MAX_OSPATH];
	struct stat st;
	extern uid_t saved_euid;
	FILE *fp;
	char message[128];
	
	
	if ( reflib_active )
	{
		Com_Printf("REFLIB ACTIVE\n");
		if (KBD_Close_fp)
			KBD_Close_fp();
		if (RW_IN_Shutdown_fp)
			RW_IN_Shutdown_fp();
		KBD_Close_fp = NULL;
		RW_IN_Shutdown_fp = NULL;
		R_Shutdown();
		VID_FreeReflib ();
	}
	
	Com_Printf( "------- Loading %s -------\n", name );	
	
	if ((reflib_library = dlopen (name, RTLD_LAZY|RTLD_GLOBAL)) == 0)
	{

		Com_Printf("LoadLibrary (\"%s\") failed.\n", dlerror());
		return false;
	}
	


	// Init IN (Mouse) 
	n_state.IN_CenterView_fp = IN_CenterView;
	n_state.Key_Event_fp = Do_Key_Event;
	n_state.viewangles = cl.viewangles;
	n_state.in_strafe_state = &in_strafe.state;


	RW_IN_Init_fp=RW_IN_Init;

	RW_IN_Shutdown_fp=RW_IN_Shutdown;
	RW_IN_Activate_fp = RW_IN_Activate; 
	RW_IN_Commands_fp = RW_IN_Commands;
	RW_IN_Move_fp = RW_IN_Move;
	RW_IN_Frame_fp = RW_IN_Frame;

	Real_IN_Init();


	if ( R_Init( 0, 0,message ) == false )
	{
		Com_Printf("Render Init fail: %s\n",message);
		//R_Shutdown();
		//VID_FreeReflib ();
		return false;
	}



	// Init KBD 
	void KBD_Init(void);
	void KBD_Update(void);
	void KBD_Close(void);

	KBD_Init_fp = KBD_Init;
	KBD_Update_fp = KBD_Update;
	KBD_Close_fp = KBD_Close;

	KBD_Init_fp(Do_Key_Event);

	// give up root now
	setreuid(getuid(), getuid());
	setegid(getgid());

	Com_Printf( "------------------------------------\n");
	reflib_active = true;
	return true;
}


/*
============
VID_CheckChanges

This function gets called once just before drawing each frame, and it's sole purpose in life
is to check to see if any of the video mode parameters have changed, and if they have to 
update the rendering DLL and/or video mode to match.
============
*/
void VID_CheckChanges (void)
{
	char name[128];
	//cvar_t *sw_mode;
	char reason[128];
	char *drive_try;
	int i;

	if ( vid_ref->modified )
	{
		S_StopAllSounds();
	}

	while (vid_ref->modified)
	{
		/*
		** refresh has changed
		*/
		vid_ref->modified = false;
		vid_fullscreen->modified = true;
		cl.refresh_prepped = false;
		cls.disable_screen = true;

		sprintf( name, "%s", Cvar_Get ("gl_driver", "libGL", CVAR_ARCHIVE)->string);

		for (i = -1; i < FALLBACK_DRIVER_COUNT; i++)
		{
			
			drive_try = (i<0)? name:opengl_drivers[i];

			Com_Printf("Attempted driver load: %s\n",drive_try);			
			gl_string=malloc(1+sizeof(char)*strlen(drive_try));
			if (!gl_string)
			    Com_Error (ERR_FATAL,"VID_CheckChanges: String Malloc fail\n");
			
			strcpy(gl_string,drive_try);
			Cvar_ForceSet("gl_driver",gl_string);
			
			
			if (VID_LoadRefresh(drive_try))
			{
			    Com_Printf("Loading driver: %s\n",drive_try);
			    break;
			}
			
		}
		
		Com_Printf("Set gl_driver to %s\n",drive_try);



		if (i >= FALLBACK_DRIVER_COUNT)
		{
		    Com_Error(ERR_FATAL, "VID_CheckChanges: No suitable GL driver\n");
		}


		gl_string=malloc(1+sizeof(char)*strlen(drive_try));
		if (!gl_string)
			Com_Error (ERR_FATAL,"VID_CheckChanges: String Malloc fail\n");

		strcpy(gl_string,drive_try);
		Cvar_ForceSet("gl_driver",gl_string);
		Com_Printf("Set gl_driver to %s\n",drive_try);
		
		/*
		if (!R_Init( 0, 0, reason) == -1)
		  {
		    R_Shutdown();
		    VID_FreeReflib();
		    Com_Error("Couldn't initialize renderer: %s",reason);
		  }
		*/
		cls.disable_screen = false;
	}




}

/*
============
VID_Init
============
*/
void VID_Init (void)
{
	/* Create the video variables so we know how to start the graphics drivers */
	// if DISPLAY is defined, try X
	if (getenv("DISPLAY"))
		vid_ref = Cvar_Get ("vid_ref", "softx", CVAR_ARCHIVE);
	else
		vid_ref = Cvar_Get ("vid_ref", "soft", CVAR_ARCHIVE);
	vid_xpos = Cvar_Get ("vid_xpos", "3", CVAR_ARCHIVE);
	vid_ypos = Cvar_Get ("vid_ypos", "22", CVAR_ARCHIVE);
	vid_fullscreen = Cvar_Get ("vid_fullscreen", "0", CVAR_ARCHIVE);
	vid_gamma = Cvar_Get( "vid_gamma", "0.5", CVAR_ARCHIVE );
	r_customwidth = Cvar_Get( "r_customwidth", "1600", CVAR_ARCHIVE );
	r_customheight = Cvar_Get( "r_customheight", "1024", CVAR_ARCHIVE );

	/* Add some console commands that we want to handle */
	Cmd_AddCommand ("vid_restart", VID_Restart_f);

	/* Disable the 3Dfx splash screen */
	putenv("FX_GLIDE_NO_SPLASH=0");
		
	/* Start the graphics mode and load refresh DLL */

	vid_ref->modified = true; 
	VID_CheckChanges();

}

/*
============
VID_Shutdown
============
*/
void VID_Shutdown (void)
{
	if ( reflib_active )
	{
		if (KBD_Close_fp)
			KBD_Close_fp();
		if (RW_IN_Shutdown_fp)
			RW_IN_Shutdown_fp();
		KBD_Close_fp = NULL;
		RW_IN_Shutdown_fp = NULL;
		R_Shutdown ();
		VID_FreeReflib ();
	}
}


/*****************************************************************************/
/* INPUT                                                                     */
/*****************************************************************************/

cvar_t	*in_joystick;

// This is fake, it's acutally done by the Refresh load
void IN_Init (void)
{
	in_joystick	= Cvar_Get ("in_joystick", "0", CVAR_ARCHIVE);
}

void Real_IN_Init (void)
{
	if (RW_IN_Init_fp)
		RW_IN_Init_fp(&n_state);
}

void IN_Shutdown (void)
{
	if (RW_IN_Shutdown_fp)
		RW_IN_Shutdown_fp();
}

void IN_Commands (void)
{
	if (RW_IN_Commands_fp)
		RW_IN_Commands_fp();
}

void IN_Move (usercmd_t *cmd)
{
	if (RW_IN_Move_fp)
		RW_IN_Move_fp(cmd);
}

void IN_Frame (void)
{
	if (RW_IN_Activate_fp) 
	{	// Knightmare changed
		if ( !cl.refresh_prepped || cls.consoleActive //cls.key_dest == key_console
			|| cls.key_dest == key_menu)
			RW_IN_Activate_fp(false);
		else
			RW_IN_Activate_fp(true);
	}

	if (RW_IN_Frame_fp)
		RW_IN_Frame_fp();
}

void IN_Activate (qboolean active)
{
}

void Do_Key_Event(int key, qboolean down)
{
	Key_Event(key, down, Sys_Milliseconds());
}

