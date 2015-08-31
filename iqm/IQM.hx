// https://github.com/snowkit/iqm

package iqm;

import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

import iqm.IQMData;

class IQM {


    public var error: Dynamic;
    public var header: IQMHeader;
    public var vertex_arrays: Array<IQMVertexArray>;
    public var indices: Bytes;
    public var meshes: Array<IQMMesh>;
    public var joints: Array<IQMJoint>;
    public var anims:Array<IQMAnim>;
    public var poses:Array<IQMPose>;
    public var frames:Array<IQMFrame>;

//Public API

    public function new() {}

        /** Cleans up data used by this instance */
    public function destroy() : Void {
        error = null;
        header = null;
        vertex_arrays = null;
        indices = null;
        meshes = null;
        joints = null;
        anims = null;
        poses = null;
        frames = null;
    }

//Public static API

        /** Parse the given bytes as IQM binary data.
            Will validate the mesh, and will return null on invalid data. */
    public static function parse(_bytes:haxe.io.Bytes, ?_req_ver:Int=2) : IQM {

        var _input = new BytesInput(_bytes);
            _input.bigEndian = false;

        if(!validate_input(_input, _req_ver)) {
            _input = null;
            return null;
        }

        var _iqm_inst = new IQM();
        if(!_iqm_inst.parse_input(_input)) {
            return null;
        }

        return _iqm_inst;

    } //parse

        /** Validates the given bytes is the required version and IQM binary data */
    public static function validate(_bytes:haxe.io.Bytes, ?_req_ver:Int=2) : Bool {

        var _input = new BytesInput(_bytes);
            _input.bigEndian = false;

        var _res = validate_input(_input, _req_ver);

        _input = null;

        return _res;

    } //validate


//Internal

    inline static function validate_input( _input:BytesInput, _req_ver:Int ) : Bool {

        var _id = _input.readString(16);
        var _ver = _input.readInt32();

        var _id_valid = StringTools.startsWith(_id, "INTERQUAKEMODEL");
        var _ver_valid = _ver == _req_ver;

        _id = null;

        return _id_valid && _ver_valid;

    } //validate_input

//Parsing

    function parse_header(_input:BytesInput) : IQMHeader {

        return {
            filesize:           _input.readInt32(),
            flags:              _input.readInt32(),
            num_text:           _input.readInt32(),
            ofs_text:           _input.readInt32(),
            num_meshes:         _input.readInt32(),
            ofs_meshes:         _input.readInt32(),
            num_vertexarrays:   _input.readInt32(),
            num_vertices:       _input.readInt32(),
            ofs_vertexarrays:   _input.readInt32(),
            num_triangles:      _input.readInt32(),
            ofs_triangles:      _input.readInt32(),
            ofs_adjacency:      _input.readInt32(),
            num_joints:         _input.readInt32(),
            ofs_joints:         _input.readInt32(),
            num_poses:          _input.readInt32(),
            ofs_poses:          _input.readInt32(),
            num_anims:          _input.readInt32(),
            ofs_anims:          _input.readInt32(),
            num_frames:         _input.readInt32(),
            num_framechannels:  _input.readInt32(),
            ofs_frames:         _input.readInt32(),
            ofs_bounds:         _input.readInt32(),
            num_comment:        _input.readInt32(),
            ofs_comment:        _input.readInt32(),
            num_extensions:     _input.readInt32(),
            ofs_extensions:     _input.readInt32(),
        };

    } //parse_header

    function parse_vertex_arrays(_input:BytesInput) : Array<IQMVertexArray> {

        var _count = header.num_vertexarrays;

        if(_count <= 0) return [];

        // vertexarrays are non-interleaved component buffers
        _input.position = header.ofs_vertexarrays;

        var _result = [];
        var _idx = 0;

        while(_idx < _count) {

            var _va:IQMVertexArray = {
                type:   _input.readInt32(),
                flags:  _input.readInt32(),
                format: _input.readInt32(),
                size:   _input.readInt32(),
                offset: _input.readInt32()
            }

            if(!validate_vertex_array(_va)) {
                _va = null;
                continue;
            }

            var _elembytes = bytes_for_vertex_array_type(_va.type);
            var _va_length = header.num_vertices * _va.size * _elembytes;

            _va.bytes = Bytes.alloc(_va_length);

            var _pre = _input.position;

                _input.position = _va.offset;
                _input.readBytes(_va.bytes, 0, _va_length);

            _input.position = _pre;

            _result.push(_va);

            ++_idx;

        } //while count

        return _result;

    } //parse_vertex_arrays

    function parse_indices(_input:BytesInput) : Bytes {

            // triangles are indexbuffers
        _input.position = header.ofs_triangles;
            //3 points per triangle, 4 bytes per float
        var _tris_length = header.num_triangles * 3 * 4;
        var _result = Bytes.alloc(_tris_length);

        _input.readBytes(_result, 0, _tris_length);

        return _result;

    } //parse_indices

    function parse_meshes(_input:BytesInput) : Array<IQMMesh> {

        var _count = header.num_meshes;
        if(_count <= 0) return [];

        var _result = [];
        var _idx = 0;

        while(_idx < _count) {

            _input.position = header.ofs_meshes + (_idx * 24);

            var _mesh_name_pos      = _input.readInt32() + header.ofs_text;
            var _material_name_pos  = _input.readInt32() + header.ofs_text;

            var m:IQMMesh = {
                name: null,
                material: null,
                first_vertex:   _input.readInt32(),
                num_vertices:   _input.readInt32(),
                first_triangle: _input.readInt32(),
                num_triangles:  _input.readInt32()
            }

            // read strings
            m.name = read_string(_input, _mesh_name_pos);
            m.material = read_string(_input, _material_name_pos);

            _result.push(m);
            _idx++;

        } //while _count

        return _result;

    } //parse_meshes

    function parse_joints(_input:BytesInput) : Array<IQMJoint> {

        var _count = header.num_joints;
        if(_count <= 0) return [];

        var _result = [];
        var _idx = 0;

        while(_idx < _count) {

            _input.position = header.ofs_joints + (_idx * 48);

            var _joint_name_pos = _input.readInt32() + header.ofs_text;

            var _joint: IQMJoint = {
                name: null,
                parent: _input.readInt32(),
                translate:[
                    _input.readFloat(),
                    _input.readFloat(),
                    _input.readFloat()
                ],
                rotate:[
                    _input.readFloat(),
                    _input.readFloat(),
                    _input.readFloat(),
                    _input.readFloat()
                ],
                scale:[
                    _input.readFloat(),
                    _input.readFloat(),
                    _input.readFloat()
                ]
            }

            _joint.name = read_string(_input, _joint_name_pos);

            _result.push(_joint);

            _idx++;

        } //while _count

        return _result;

    } //parse_joints

    function parse_anims(_input:BytesInput) : Array<IQMAnim> {

        var _count = header.num_anims;
        if(_count <= 0) return [];

        var _result = [];
        var _idx = 0;

        while(_idx < _count) {

            _input.position = header.ofs_anims + (_idx * 20);

            var _anim_name_pos = _input.readInt32() + header.ofs_text;

            var _anim:IQMAnim = {
                name:        null,
                first_frame: _input.readInt32(),
                num_frames:  _input.readInt32(),
                framerate:   _input.readFloat(),
                flags:       _input.readInt32()
            };

            _anim.name = read_string(_input, _anim_name_pos);

            _result.push(_anim);

            _idx++;

        } //while _count

        return _result;

    } //parse_anims

    function parse_poses(_input:BytesInput) : Array<IQMPose> {

        var _count = header.num_poses;
        if(_count <= 0) return [];

        var _result = [];
        var _idx = 0;
        var _j = 0;

        _input.position = header.ofs_poses;

        while(_idx < _count) {

            var _pose: IQMPose = {
                parent: _input.readInt32(),
                channelmask: _input.readInt32(),
                channeloffset: [],
                channelscale: [],
            }

            _j = 0;
            while(_j < 10) {
                _pose.channeloffset.push(_input.readFloat());
                ++_j;
            }

            _j = 0;
            while(_j < 10) {
                _pose.channelscale.push(_input.readFloat());
                ++_j;
            }

            _result.push(_pose);

            _idx++;

        } //while _count

        return _result;

    } //parse_poses

    function parse_frames(_input:BytesInput) : Array<IQMFrame> {

        var _count = header.num_frames;
        if(_count <= 0) return [];

        var _result = [];

        _input.position = header.ofs_frames;

        for(i in 0..._count) {
            for (j in 0...header.num_poses) {

                var _pose = poses[j];
                var _mask = _pose.channelmask;
                var _scale = _pose.channelscale;
                var _offset = _pose.channeloffset;

                var _px = _offset[IQM_POSE_Tx];
                var _py = _offset[IQM_POSE_Ty]; 
                var _pz = _offset[IQM_POSE_Tz];

                var _rx = _offset[IQM_POSE_Qx];
                var _ry = _offset[IQM_POSE_Qy];
                var _rz = _offset[IQM_POSE_Qz]; 
                var _rw = _offset[IQM_POSE_Qw];

                var _sx = _offset[IQM_POSE_Sx];
                var _sy = _offset[IQM_POSE_Sy]; 
                var _sz = _offset[IQM_POSE_Sz];

                if(_mask & 0x01 != 0)  _px += _input.readUInt16() * _scale[IQM_POSE_Tx];
                if(_mask & 0x02 != 0)  _py += _input.readUInt16() * _scale[IQM_POSE_Ty];
                if(_mask & 0x04 != 0)  _pz += _input.readUInt16() * _scale[IQM_POSE_Tz];
                if(_mask & 0x08 != 0)  _rx += _input.readUInt16() * _scale[IQM_POSE_Qx];
                if(_mask & 0x10 != 0)  _ry += _input.readUInt16() * _scale[IQM_POSE_Qy];
                if(_mask & 0x20 != 0)  _rz += _input.readUInt16() * _scale[IQM_POSE_Qz];
                if(_mask & 0x40 != 0)  _rw += _input.readUInt16() * _scale[IQM_POSE_Qw];
                if(_mask & 0x80 != 0)  _sx += _input.readUInt16() * _scale[IQM_POSE_Sx];
                if(_mask & 0x100 != 0) _sy += _input.readUInt16() * _scale[IQM_POSE_Sy];
                if(_mask & 0x200 != 0) _sz += _input.readUInt16() * _scale[IQM_POSE_Sz];

                _result.push({
                    translate:[_px, _py, _pz],
                    rotate:[_rx,_ry,_rz,_rw],
                    scale:[_sx,_sy,_sz]
                });

            } //num poses
        } //num frames

        return _result;

    } //parse_frames

    function parse_input(_input:BytesInput) : Bool {

        try {
            header = parse_header(_input);
            meshes = parse_meshes(_input);
            vertex_arrays = parse_vertex_arrays(_input);
            indices = parse_indices(_input);
            joints = parse_joints(_input);
            anims = parse_anims(_input);
            poses = parse_poses(_input);
            frames = parse_frames(_input);
        } catch(e:Dynamic) {
            error = e;
            return false;
        }

        return true;

    } //parse_input

//Helpers

    public static function dump(_iqm:IQM) {
        trace('header: \n    ${_iqm.header}');

        trace('vertex arrays: ${_iqm.vertex_arrays.length}');
        for(_va in _iqm.vertex_arrays) {
            trace('    type: ${_va.type} (${_va.bytes.length} bytes)');
            trace('        flags: ${_va.flags} format: ${_va.format} size: ${_va.size} offset: ${_va.offset}');
        }

        trace('meshes: ${_iqm.meshes.length}');
        for(m in _iqm.meshes) {
            trace('    "${m.name}" with material: "${m.material}"');
            trace('        first_vertex: ${m.first_vertex} num_vertices: ${m.num_vertices} first_triangle: ${m.first_triangle} num_triangles: ${m.num_triangles}');
        }

        trace('anims: ${_iqm.anims.length}');
        for(a in _iqm.anims) {
            trace('    "${a.name}" with framerate: ${a.framerate}');
            trace('        first_frame: ${a.first_frame} num_frames: ${a.num_frames} flags: ${a.flags}');
        }

        trace('poses: ${_iqm.poses.length}');
        for(p in _iqm.poses) {
            trace('    parent: ${p.parent} with mask:  ${IQMPoseChannel.list(p.channelmask)} (${p.channelmask})');
            trace('        channeloffset: ${p.channeloffset}');
            trace('        channelscale: ${p.channelscale}');
        }

        trace('frames: ${_iqm.frames.length}');
        // var _fidx = 0;
        // for(f in _iqm.frames) {
        //     trace('    frame: $_fidx');
        //     trace('        translate: ${f.translate} rotate: ${f.rotate} scale: ${f.scale}');
        //     _fidx++;
        // }

        trace('joints: ${_iqm.joints.length}');
        for(j in _iqm.joints) {
            trace('    "${j.name}" with parent: ${j.parent}');
            trace('        translate: ${j.translate}   rotate: ${j.rotate}    scale: ${j.scale}');
        }
    }

//Internal

    function bytes_for_vertex_array_type(_va_type:IQMVertexArrayType) : Int {
        return switch(_va_type) {
            case IQM_POSITION:      4;
            case IQM_NORMAL:        4;
            case IQM_TANGENT:       4;
            case IQM_TEXCOORD:      4;
            case IQM_BLENDINDEXES:  1;
            case IQM_BLENDWEIGHTS:  1;
            case IQM_COLOR:         1;
            case _:                 0;
        }
    }

    function validate_vertex_array(_va:IQMVertexArray) {
        return switch(_va.type) {
            case IQM_POSITION:      _va.format == IQM_FLOAT && _va.size == 3;
            case IQM_NORMAL:        _va.format == IQM_FLOAT && _va.size == 3;
            case IQM_TANGENT:       _va.format == IQM_FLOAT && _va.size == 4;
            case IQM_TEXCOORD:      _va.format == IQM_FLOAT && _va.size == 2;
            case IQM_BLENDINDEXES:  _va.format == IQM_UBYTE && _va.size == 4;
            case IQM_BLENDWEIGHTS:  _va.format == IQM_UBYTE && _va.size == 4;
            case IQM_COLOR:         _va.format == IQM_UBYTE && _va.size == 4;
            case _: return false;
        }
    }

    inline function read_string(_fin:BytesInput, _pos:Int):String {
        _fin.position = _pos;
        var buf = new StringBuf();
        while(true) {
            var c = _fin.readByte();
            if (c == 0x00) break;
            buf.addChar(c);
        }
        return buf.toString();
    }
}