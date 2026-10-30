
#import <unistd.h>
#import <errno.h>

pid_t fork(void) {
    errno = EAGAIN;
    return -1;
}
