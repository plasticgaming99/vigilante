// vigctl server

module main

import json2
import vigctl.lib as vigctllib

const proto_version = 1

fn vigctl_do(s string, mut vr VigRegistry) string {
	vdt := json2.decode[vigctllib.VigDataType](s) or {return "Error decoding vigctl data."}
	mut rt_vdt := vigctllib.VigDataType{}
	rt_vdt.proto_version = proto_version
	rt_vdt.purpose = vigctllib.vigctl_return
	match vdt.purpose {
		vigctllib.vigctl_start {
			//println("vigctl: revieved service name ${vdt.content}")
			if vdt.content == "" {
				rt_vdt.content = "Invailed service name entered."
				return json2.encode(rt_vdt)
			}
			if vr.vigsvcs[vdt.content].internal.state == int(ServiceState.running) {
				rt_vdt.content = "Service ${vdt.content} is already started."
				return json2.encode(rt_vdt)
			}
			vr.start_service_tree(vdt.content.clone())
			//println("yo start-ish thing finished, btw service name is ${vdt.content}")
			rt_vdt.content = "Started service ${vdt.content}"
			return json2.encode(rt_vdt)
		}
		vigctllib.vigctl_stop {
			if vdt.content == "" {
				rt_vdt.content = "Invailed service name entered."
				return json2.encode(rt_vdt)
			}
			if vr.vigsvcs[vdt.content].internal.state == int(ServiceState.stopped) {
				rt_vdt.content = "Service ${vdt.content} is already stopped."
				return json2.encode(rt_vdt)
			}
			vr.stop_service(vdt.content)
			rt_vdt.content = "Stopped service ${vdt.content}"
			return json2.encode(rt_vdt)
		}
		vigctllib.vigctl_shutdown {exit(0)}
		else {
			rt_vdt.content = "${vdt.content} is Invailed context, or not implemented yet"
			return json2.encode(rt_vdt)
		}
	}
	return ""
}
