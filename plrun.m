#include <spawn.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <signal.h>
#include <errno.h>

#import "dlfcn.h"

/* Flags for entp command. Any combination or none can be specified. */
/* Wait for xpcproxy to exec before continuing */
#define FLAG_WAIT_EXEC   (1 << 5)
/* Wait for 0.5 sec after acting */
#define FLAG_DELAY       (1 << 4)
/* Send SIGCONT after acting */
#define FLAG_SIGCONT     (1 << 3)
/* Set sandbox exception */
#define FLAG_SANDBOX     (1 << 2)
/* Set platform binary flag */
#define FLAG_PLATFORMIZE (1 << 1)
/* Set basic entitlements */
#define FLAG_ENTITLE     (1)
    
typedef void (*jb_oneshot_entitle_now_t)(pid_t pid, uint32_t what);

int main(int argc, char *argv[], char *envp[])
{
    if (argc < 2)
    {
        fprintf(stderr, "Usage: %s program args...\n\nRun program with TF_PLATFORM=1\nMade for electra 1.0.4\n", argv[0]);
        return EXIT_FAILURE;
    }

    void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle) 
    {
        fprintf(stderr, "Failed: %s\n", dlerror());
        return EXIT_FAILURE;
    }

    // reset errors
    dlerror();
    jb_oneshot_entitle_now_t pjb_oneshot_entitle_now = (jb_oneshot_entitle_now_t)dlsym(handle, "jb_oneshot_entitle_now");
    
    const char *dlsym_error = dlerror();
    if (dlsym_error)
    {
        fprintf(stderr, "Failed: %s\n", dlsym_error);        
        return EXIT_FAILURE;
    }                

    int status;
    pid_t pid;
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_setflags(&attr, POSIX_SPAWN_START_SUSPENDED);
    
    status = posix_spawnp(&pid, argv[1], NULL, &attr, &argv[1], envp);
    if (status == 0)
    {
        //char pid_s[16];
        //sprintf(pid_s, "%i", pid);
        //printf("Child pid: %i\n", pid);
        pjb_oneshot_entitle_now(pid, FLAG_PLATFORMIZE);
        kill(pid, SIGCONT);
        if (waitpid(pid, &status, 0) == -1)
        {
            perror("waitpid");
            return EXIT_FAILURE;
        }
    } else {
        printf("posix_spawn: %s\n", strerror(status));
    }

    //printf("Child terminated with status %i\n", status);

    return status;
}
