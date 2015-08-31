// https://github.com/snowkit/iqm

package iqm;

/**
version 2: May 31, 2011
   * explicitly store quaternion w to minimize animation jitter
     modified joint and pose struct to explicitly store quaternion w in new channel 6 (with 10 total channels)

all data is little endian

struct iqmheader
{
    char magic[16]; // the string "INTERQUAKEMODEL\0", 0 terminated
    uint version; // must be version 2
    uint filesize;
    uint flags;
    uint num_text, ofs_text;
    uint num_meshes, ofs_meshes;
    uint num_vertexarrays, num_vertexes, ofs_vertexarrays;
    uint num_triangles, ofs_triangles, ofs_adjacency;
    uint num_joints, ofs_joints;
    uint num_poses, ofs_poses;
    uint num_anims, ofs_anims;
    uint num_frames, num_framechannels, ofs_frames, ofs_bounds;
    uint num_comment, ofs_comment;
    uint num_extensions, ofs_extensions; // these are stored as a linked list, not as a contiguous array
};
*/

typedef IQMHeader = {
    var filesize: Int;
    var flags: Int;
    var num_text: Int;
    var ofs_text: Int;
    var num_meshes: Int;
    var ofs_meshes: Int;
    var num_vertexarrays: Int;
    var num_vertices: Int; 
    var ofs_vertexarrays: Int;
    var num_triangles: Int; 
    var ofs_triangles: Int; 
    var ofs_adjacency: Int;
    var num_joints: Int; 
    var ofs_joints: Int;
    var num_poses: Int; 
    var ofs_poses: Int;
    var num_anims: Int; 
    var ofs_anims: Int;
    var num_frames: Int; 
    var num_framechannels: Int; 
    var ofs_frames: Int; 
    var ofs_bounds: Int;
    var num_comment: Int; 
    var ofs_comment: Int;
    var num_extensions: Int; 
    var ofs_extensions: Int;
}

/**
struct iqmvertexarray
{
    uint type;   // type or custom name
    uint flags;
    uint format; // component format
    uint size;   // number of components
    uint offset; // offset to array of tightly packed components, with num_vertexes * size total entries
                 // offset must be aligned to max(sizeof(format), 4)
};
*/
typedef IQMVertexArray = {
    var type:IQMVertexArrayType;
    var format:IQMVertexArrayFormat;
    var flags:Int;
    var size:Int;
    var offset:Int;
    @:optional var bytes:haxe.io.Bytes;
}

@:enum
abstract IQMVertexArrayFormat(Int)
  from Int to Int {
    var IQM_BYTE   = 0;
    var IQM_UBYTE  = 1;
    var IQM_SHORT  = 2;
    var IQM_USHORT = 3;
    var IQM_INT    = 4;
    var IQM_UINT   = 5;
    var IQM_HALF   = 6;
    var IQM_FLOAT  = 7;
    var IQM_DOUBLE = 8;

    inline function toString() {
        return switch(this) {
            case IQM_BYTE:   'IQM_BYTE';
            case IQM_UBYTE:  'IQM_UBYTE';
            case IQM_SHORT:  'IQM_SHORT';
            case IQM_USHORT: 'IQM_USHORT';
            case IQM_INT:    'IQM_INT';
            case IQM_UINT:   'IQM_UINT';
            case IQM_HALF:   'IQM_HALF';
            case IQM_FLOAT:  'IQM_FLOAT';
            case IQM_DOUBLE: 'IQM_DOUBLE';
            case _:          'unknown';
        }
    }
}

@:enum
abstract IQMVertexArrayType(Int)
  from Int to Int {
    var IQM_POSITION        = 0;  // float, 3
    var IQM_TEXCOORD        = 1;  // float, 2
    var IQM_NORMAL          = 2;  // float, 3
    var IQM_TANGENT         = 3;  // float, 4
    var IQM_BLENDINDEXES    = 4;  // ubyte, 4
    var IQM_BLENDWEIGHTS    = 5;  // ubyte, 4
    var IQM_COLOR           = 6;  // ubyte, 4
    /** all values up to IQM_CUSTOM are reserved for future use
        any value >= IQM_CUSTOM is interpreted as CUSTOM type
        the value then defines an offset into the string table,
        where offset = value - IQM_CUSTOM
        this must be a valid string naming the type */
    var IQM_CUSTOM          = 0x10;

    inline function toString() {
        return switch(this) {
            case IQM_POSITION:      'IQM_POSITION';
            case IQM_TEXCOORD:      'IQM_TEXCOORD';
            case IQM_NORMAL:        'IQM_NORMAL';
            case IQM_TANGENT:       'IQM_TANGENT';
            case IQM_BLENDINDEXES:  'IQM_BLENDINDEXES';
            case IQM_BLENDWEIGHTS:  'IQM_BLENDWEIGHTS';
            case IQM_COLOR:         'IQM_COLOR';
            case _:                 'IQM_CUSTOM($this)';
        }
    }
}

/**
struct iqmmesh
{
    uint name;     // unique name for the mesh, if desired
    uint material; // set to a name of a non-unique material or texture
    uint first_vertex, num_vertexes;
    uint first_triangle, num_triangles;
};
*/
typedef IQMMesh = {
    var name: String;
    var material: String;
    var first_vertex: UInt;
    var num_vertices: UInt;
    var first_triangle: UInt;
    var num_triangles: UInt;
}

/**
struct iqmjoint
{
    uint name;
    int parent; // parent < 0 means this is a root bone
    float translate[3], rotate[4], scale[3]; 
    // translate is translation <Tx, Ty, Tz>, and rotate is quaternion rotation <Qx, Qy, Qz, Qw>
    // rotation is in relative/parent local space
    // scale is pre-scaling <Sx, Sy, Sz>
    // output = (input*scale)*rotation + translation
};
*/
typedef IQMJoint = {
    var name: String;
    var parent: Int;
    var translate: Array<Float>;
    var rotate: Array<Float>;
    var scale: Array<Float>;
}

/**
struct iqmanim
{
    uint name;
    uint first_frame, num_frames; 
    float framerate;
    uint flags;
};
*/
typedef IQMAnim = {
    var name: String;
    var first_frame: UInt;
    var num_frames: UInt;
    var framerate: Float;
    var flags: UInt;
}


@:enum
abstract IQMAnimFlags(Int)
  from Int to Int {
    var IQM_LOOP = 1<<0;

    inline function toString() {
        return switch(this) {
            case IQM_LOOP: 'IQM_LOOP';
            case _:        'unknown';
        }
    }
}

/**
struct iqmpose
{
    int parent; // parent < 0 means this is a root bone
    uint channelmask; // mask of which 10 channels are present for this joint pose
    float channeloffset[10], channelscale[10]; 
    // channels 0..2 are translation <Tx, Ty, Tz> and channels 3..6 are quaternion rotation <Qx, Qy, Qz, Qw>
    // rotation is in relative/parent local space
    // channels 7..9 are scale <Sx, Sy, Sz>
    // output = (input*scale)*rotation + translation
};
*/
typedef IQMPose = {
    var parent:Int;
    var channelmask:UInt;
    var channeloffset:Array<Float>;
    var channelscale:Array<Float>;
}

/** Store each frame data verbosely for now */
typedef IQMFrame = {
    var translate:Array<Float>;
    var scale:Array<Float>;
    var rotate:Array<Float>;
}

@:enum
abstract IQMPoseChannel(Int)
  from Int to Int {
    var IQM_POSE_Tx = 0;
    var IQM_POSE_Ty = 1;
    var IQM_POSE_Tz = 2;
    var IQM_POSE_Qx = 3;
    var IQM_POSE_Qy = 4;
    var IQM_POSE_Qz = 5;
    var IQM_POSE_Qw = 6;
    var IQM_POSE_Sx = 7;
    var IQM_POSE_Sy = 8;
    var IQM_POSE_Sz = 9;

    inline public static function has(_mask:UInt, flag:Int) {
        return (_mask & flag) == flag;
    }

    inline public static function list(_mask:UInt) {
        var _result = [];
            if((_mask & IQM_POSE_Tx) == IQM_POSE_Tx) _result.push('Tx');
            if((_mask & IQM_POSE_Ty) == IQM_POSE_Ty) _result.push('Ty');
            if((_mask & IQM_POSE_Tz) == IQM_POSE_Tz) _result.push('Tz');
            if((_mask & IQM_POSE_Qx) == IQM_POSE_Qx) _result.push('Qx');
            if((_mask & IQM_POSE_Qy) == IQM_POSE_Qy) _result.push('Qy');
            if((_mask & IQM_POSE_Qz) == IQM_POSE_Qz) _result.push('Qz');
            if((_mask & IQM_POSE_Qw) == IQM_POSE_Qw) _result.push('Qw');
            if((_mask & IQM_POSE_Sx) == IQM_POSE_Sx) _result.push('Sx');
            if((_mask & IQM_POSE_Sy) == IQM_POSE_Sy) _result.push('Sy');
            if((_mask & IQM_POSE_Sz) == IQM_POSE_Sz) _result.push('Sz');
        return _result;
    }

    inline function toString() {
        return switch(this) {
            case IQM_POSE_Tx: 'IQM_POSE_Tx';
            case IQM_POSE_Ty: 'IQM_POSE_Ty';
            case IQM_POSE_Tz: 'IQM_POSE_Tz';
            case IQM_POSE_Qx: 'IQM_POSE_Qx';
            case IQM_POSE_Qy: 'IQM_POSE_Qy';
            case IQM_POSE_Qz: 'IQM_POSE_Qz';
            case IQM_POSE_Qw: 'IQM_POSE_Qw';
            case IQM_POSE_Sx: 'IQM_POSE_Sx';
            case IQM_POSE_Sy: 'IQM_POSE_Sy';
            case IQM_POSE_Sz: 'IQM_POSE_Sz';
            case _:        'unknown';
        }
    }
}

