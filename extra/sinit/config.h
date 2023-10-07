/* See LICENSE file for copyright and license details. */

static char *const rcinitcmd[]     = { "/etc/sinit/rc.init", NULL };
static char *const rcrebootcmd[]   = { "/etc/sinit/rc.shutdown", "reboot", NULL };
static char *const rcpoweroffcmd[] = { "/etc/sinit/rc.shutdown", "poweroff", NULL };
