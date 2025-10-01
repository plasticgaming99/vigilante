// vigctl server

module main

import x.json2
import vigctl.lib as vigctllib

const proto_version = 1

fn vigctl_do(s string, mut vr VigRegistry) string {
	vdt := json2.decode[vigctllib.VigDataType](s) or {return "Error decoding vigctl data."}
	mut rt_vdt := vigctllib.VigDataType{}
	rt_vdt.proto_version = proto_version
	rt_vdt.purpose = vigctllib.vigctl_return
	match vdt.purpose {
		"start" {
			if vdt.content == "" {
				rt_vdt.purpose = "Invailed service name entered."
				return json2.encode[vigctllib.VigDataType](rt_vdt)
			}
			vr.start_service_tree(vdt.content)
			rt_vdt.content = "Started service ${vdt.content}"
			return json2.encode[vigctllib.VigDataType](rt_vdt)
		}
		"shutdown" {exit(0)}
		else {
			rt_vdt.content = "${vdt.content} is Invailed context, or not implemented yet"
			return json2.encode[vigctllib.VigDataType](rt_vdt)
		}
	}
	return ""
}
