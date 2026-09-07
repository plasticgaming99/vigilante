module syscall

#include <linux/prctl.h>
#include <sys/prctl.h>

pub const pr_set_child_subreaper = /*C.PR_SET_CHILD_SUBREAPER*/ 36
pub const pr_get_child_subreaper = /*C.PR_GET_CHILD_SUBREAPER*/ 37

pub fn C.prctl(op int...) int