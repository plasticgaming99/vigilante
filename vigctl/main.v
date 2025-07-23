module main

import msgpack
import lib
import x.json2

fn main() {
	println('placeholder!!')
	mut data := lib.VigDataType{
		proto_version: 1
		purpose: lib.vigctl_start
	}
	mut msgenc := msgpack.new_encoder()
	dt := msgenc.encode(data)
	println(msgenc.str())
	mut msgdec := msgpack.new_decoder()
	mut datatype := lib.VigDataType{}
	txt := msgdec.decode_to_json[lib.VigDataType](dt) or { 
		""
	}
	datatype = json2.decode[lib.VigDataType](txt) or { lib.VigDataType{} }
	unsafe{txt.free()}
	println(datatype)
}