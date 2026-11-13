#include "body_resolver_core.hpp"
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/rect2i.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {
class WarbeastBodyM94 : public RefCounted {
    GDCLASS(WarbeastBodyM94,RefCounted)
protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("solve","bodies","bounds","max_step"),&WarbeastBodyM94::solve);
        ClassDB::bind_method(D_METHOD("solve_bodies","bodies","bounds","max_step"),&WarbeastBodyM94::solve_bodies);
    }
    static Dictionary declined(const String &reason) {
        Dictionary result;result["accepted"]=false;result["positions"]=Dictionary();result["reason"]=reason;return result;
    }
public:
    // One call for the WHOLE resolver, not one callback per body/property.
    // Variant access remains here solely for validation/pack/unpack; the core
    // never reads a Dictionary and the returned map retains no input aliases.
    Dictionary solve_bodies(const Array &input,const Rect2i &bounds,std::int64_t maximum_step) const {
        if (maximum_step<0 || maximum_step>warbeast_m94::step_limit || input.size()>static_cast<std::int64_t>(warbeast_m94::max_rows))
            return declined("UNSUPPORTED_COUNT_OR_GLOBAL_STEP");
        struct Row {String id;Dictionary body;};
        std::vector<Row> ordered;ordered.reserve(input.size());
        for (std::int64_t i=0;i<input.size();++i) {
            const Variant value=input[i];
            if (value.get_type()!=Variant::DICTIONARY) return declined("BODY_NOT_DICTIONARY");
            const Dictionary body=value;
            const Variant id=body.get("id",Variant());
            if (id.get_type()!=Variant::STRING) return declined("ID_NOT_STRING");
            ordered.push_back({String(id),body});
        }
        // Use Godot String's actual ordering, not UTF8/std::string collation.
        std::sort(ordered.begin(),ordered.end(),[](const Row &a,const Row &b){return a.id<b.id;});
        for (std::size_t i=1;i<ordered.size();++i)
            if (ordered[i-1].id==ordered[i].id) return declined("DUPLICATE_STRING_ID");
        std::vector<std::int32_t> words;words.resize(ordered.size()*warbeast_m94::body_stride);
        for (std::size_t i=0;i<ordered.size();++i) {
            const Dictionary &body=ordered[i].body;
            const Variant old_value=body.get("position",Variant());
            const Variant desired_value=body.get("desired",Variant());
            const Variant radius_value=body.get("radius",Variant());
            const Variant active_value=body.get("active",Variant());
            if (old_value.get_type()!=Variant::VECTOR2I || desired_value.get_type()!=Variant::VECTOR2I)
                return declined("POSITION_OR_DESIRED_NOT_VECTOR2I");
            if (radius_value.get_type()!=Variant::INT || active_value.get_type()!=Variant::BOOL)
                return declined("RADIUS_OR_ACTIVE_TYPE");
            const std::int64_t radius=radius_value;
            if (radius<0 || radius>warbeast_m94::radius_limit) return declined("RADIUS_DOMAIN");
            const Vector2i old_position=old_value,desired=desired_value;
            std::int32_t flags=bool(active_value)?warbeast_m94::active_flag:0;
            if (body.has("static")) {
                const Variant fixed=body.get("static",Variant());
                if (fixed.get_type()!=Variant::BOOL) return declined("STATIC_NOT_BOOL");
                if (bool(fixed)) flags|=warbeast_m94::static_flag;
            }
            std::int64_t movement=maximum_step;
            if (body.has("max_step")) {
                const Variant step=body.get("max_step",Variant());
                if (step.get_type()!=Variant::INT) return declined("MAX_STEP_NOT_INT");
                movement=std::min(maximum_step,std::max<std::int64_t>(0,static_cast<std::int64_t>(step)));
            }
            std::int32_t layer=0;
            if (body.has("movement_layer")) {
                const Variant label=body.get("movement_layer",Variant());
                if (label.get_type()!=Variant::STRING) return declined("LAYER_NOT_STRING");
                const String name=label;
                if (name=="AIR") layer=1;
                else if (name!="GROUND") return declined("UNKNOWN_LAYER");
            }
            Vector2i goal=desired,previous=old_position;
            if (body.has("steering_goal")) {
                const Variant value=body.get("steering_goal",Variant());
                if (value.get_type()!=Variant::VECTOR2I) return declined("STEERING_GOAL_NOT_VECTOR2I");
                goal=value;flags|=warbeast_m94::has_goal_flag;
            }
            if (body.has("previous_position")) {
                const Variant value=body.get("previous_position",Variant());
                if (value.get_type()!=Variant::VECTOR2I) return declined("PREVIOUS_NOT_VECTOR2I");
                previous=value;
            }
            const auto offset=i*warbeast_m94::body_stride;
            words[offset]=old_position.x;words[offset+1]=old_position.y;
            words[offset+2]=desired.x;words[offset+3]=desired.y;
            words[offset+4]=static_cast<std::int32_t>(radius);words[offset+5]=flags;words[offset+6]=layer;
            words[offset+7]=static_cast<std::int32_t>(movement);
            words[offset+8]=goal.x;words[offset+9]=goal.y;words[offset+10]=previous.x;words[offset+11]=previous.y;
        }
        const std::int32_t bound_words[]={bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y};
        const auto resolved=warbeast_m94::solve(words.empty()?nullptr:words.data(),words.size(),bound_words,4,maximum_step);
        if (resolved.status!=warbeast_m94::Status::ok)
            return declined(resolved.status==warbeast_m94::Status::dense_fallback?"DENSE_FALLBACK":"UNSUPPORTED_LAYOUT_OR_DOMAIN");
        if (resolved.positions.size()!=ordered.size()) return declined("INTERNAL_RESULT_COUNT");
        Dictionary positions;
        for (std::size_t i=0;i<ordered.size();++i)
            positions[ordered[i].id]=Vector2i(resolved.positions[i].x,resolved.positions[i].y);
        Dictionary result;result["accepted"]=true;result["positions"]=positions;result["reason"]="OK";return result;
    }
    PackedInt32Array solve(const PackedInt32Array &bodies,const PackedInt32Array &bounds,std::int64_t max_step) const {
        const auto result=warbeast_m94::solve(bodies.is_empty()?nullptr:bodies.ptr(),bodies.size(),
            bounds.is_empty()?nullptr:bounds.ptr(),bounds.size(),max_step);
        PackedInt32Array output;
        const bool ok=result.status==warbeast_m94::Status::ok;
        output.resize(2+(ok?result.positions.size()*2:0));
        auto *p=output.ptrw();p[0]=static_cast<std::int32_t>(result.status);p[1]=ok?static_cast<std::int32_t>(result.positions.size()):0;
        if (ok) for (std::size_t i=0;i<result.positions.size();++i) {p[2+i*2]=result.positions[i].x;p[3+i*2]=result.positions[i].y;}
        return output;
    }
};
void initialize_m94_body(ModuleInitializationLevel level) {
    if (level==MODULE_INITIALIZATION_LEVEL_SCENE) ClassDB::register_class<WarbeastBodyM94>();
}
void uninitialize_m94_body(ModuleInitializationLevel) {}
}
extern "C" {
GDExtensionBool GDE_EXPORT warbeast_m94_body_library_init(GDExtensionInterfaceGetProcAddress get_proc_address,
    GDExtensionClassLibraryPtr library,GDExtensionInitialization *initialization) {
    godot::GDExtensionBinding::InitObject init(get_proc_address,library,initialization);
    init.register_initializer(godot::initialize_m94_body);
    init.register_terminator(godot::uninitialize_m94_body);
    init.set_minimum_library_initialization_level(godot::MODULE_INITIALIZATION_LEVEL_SCENE);
    return init.init();
}
}
