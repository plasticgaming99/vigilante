module syscall

#include <linux/prctl.h>
#include <sys/prctl.h>

pub const pr_set_child_subreaper = C.PR_SET_CHILD_SUBREAPER
pub const pr_get_child_subreaper = C.PR_GET_CHILD_SUBREAPER

pub fn C.prctl(op int...) int