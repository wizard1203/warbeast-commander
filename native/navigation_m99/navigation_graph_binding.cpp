#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <vector>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/rect2i.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector2i.hpp>

namespace godot {
// Experimental whole-graph pure-math bridge. No fields, callbacks, threads,
// retained input Variants, authority references or cross-query caches.
class WarbeastNavigationM99 : public RefCounted {
    GDCLASS(WarbeastNavigationM99, RefCounted)
    static constexpr std::int32_t domain = 32768;
    static bool in_domain(const Vector2i &point) {
        return point.x >= -domain && point.x <= domain && point.y >= -domain && point.y <= domain;
    }
    static Dictionary declined(const String &reason) {
        Dictionary result; result["accepted"] = false; result["path"] = Array(); result["reason"] = reason; return result;
    }
    static bool edge_clear(const Vector2i &start, const Vector2i &target,
        const Vector2 *centers, const double *squares, const std::vector<Rect2i> &rectangles) {
        const auto min_x = std::min(start.x, target.x), max_x = std::max(start.x, target.x);
        const auto min_y = std::min(start.y, target.y), max_y = std::max(start.y, target.y);
        const Vector2 segment = Vector2(target - start);
        const bool stationary = segment.is_zero_approx();
        // Script float variables are double, but Vector2 operations are real_t.
        // Preserve the exact operation/conversion sequence of _linear_edge_clear_m90.
        const double segment_length_sq = segment.length_squared();
        const Vector2 segment_start = Vector2(start);
        const Rect2i edge_rectangle(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1));
        for (std::size_t index = 0; index < rectangles.size(); ++index) {
            if (!rectangles[index].intersects(edge_rectangle)) continue;
            const Vector2 point = centers[index];
            double distance_sq;
            if (stationary) distance_sq = (point - segment_start).length_squared();
            else {
                const double progress = std::clamp(static_cast<double>((point - segment_start).dot(segment)) / segment_length_sq, 0.0, 1.0);
                // GDScript converts the double multiplier to Vector2's real_t.
                distance_sq = point.distance_squared_to(segment_start + segment * static_cast<real_t>(progress));
            }
            if (distance_sq < squares[index]) return false;
        }
        return true;
    }
protected:
    static void _bind_methods() {
        ClassDB::bind_method(D_METHOD("solve_graph", "nodes", "centers", "reach_squares", "rectangles"), &WarbeastNavigationM99::solve_graph);
    }
public:
    Dictionary solve_graph(const Array &input_nodes, const PackedVector2Array &centers,
        const PackedFloat64Array &reach_squares, const Array &input_rectangles) const {
        if (input_nodes.size() < 2 || input_nodes.size() > 258 || centers.size() < 16 || centers.size() > 1024
            || reach_squares.size() != centers.size() || input_rectangles.size() != centers.size())
            return declined("UNSUPPORTED_COUNTS");
        std::vector<Vector2i> nodes; nodes.reserve(input_nodes.size());
        std::vector<Vector2> node_vectors; node_vectors.reserve(input_nodes.size());
        for (std::int64_t index = 0; index < input_nodes.size(); ++index) {
            const Variant value = input_nodes[index];
            if (value.get_type() != Variant::VECTOR2I) return declined("NODE_NOT_VECTOR2I");
            const Vector2i point = value;
            if (!in_domain(point)) return declined("NODE_OUTSIDE_PREPARED_DOMAIN");
            nodes.push_back(point); node_vectors.emplace_back(point);
        }
        std::vector<Rect2i> rectangles; rectangles.reserve(input_rectangles.size());
        const Vector2 *center_data = centers.ptr();
        const double *square_data = reach_squares.ptr();
        for (std::int64_t index = 0; index < centers.size(); ++index) {
            const Vector2 center = center_data[index];
            if (!std::isfinite(center.x) || !std::isfinite(center.y) || center.x < -domain || center.x > domain
                || center.y < -domain || center.y > domain || std::trunc(center.x) != center.x || std::trunc(center.y) != center.y)
                return declined("CENTER_OUTSIDE_PREPARED_DOMAIN");
            if (!std::isfinite(square_data[index]) || square_data[index] < 0.0 || square_data[index] > 4294967296.0)
                return declined("REACH_SQUARE_OUTSIDE_PREPARED_DOMAIN");
            const Variant value = input_rectangles[index];
            if (value.get_type() != Variant::RECT2I) return declined("RECTANGLE_NOT_RECT2I");
            const Rect2i rectangle = value;
            // Derived original rectangles fit this generous integer-safe domain.
            if (rectangle.size.x < 0 || rectangle.size.y < 0 || rectangle.size.x > 200000 || rectangle.size.y > 200000
                || rectangle.position.x < -200000 || rectangle.position.x > 200000
                || rectangle.position.y < -200000 || rectangle.position.y > 200000)
                return declined("RECTANGLE_OUTSIDE_PREPARED_DOMAIN");
            rectangles.push_back(rectangle);
        }
        const auto count = nodes.size();
        std::vector<double> distances(count, std::numeric_limits<double>::infinity());
        std::vector<std::int32_t> previous(count, -1);
        std::vector<bool> visited(count, false);
        distances[0] = 0.0;
        // Same ascending scan, strict < comparisons and target break as script.
        for (std::size_t iteration = 0; iteration < count; ++iteration) {
            std::int32_t current = -1;
            double best = std::numeric_limits<double>::infinity();
            for (std::size_t index = 0; index < count; ++index) {
                if (!visited[index] && distances[index] < best) { best = distances[index]; current = static_cast<std::int32_t>(index); }
            }
            if (current < 0 || current == 1) break;
            visited[current] = true;
            const Vector2 current_vector = node_vectors[current];
            const double current_distance = distances[current];
            for (std::size_t next = 1; next < count; ++next) {
                if (visited[next] || next == static_cast<std::size_t>(current)) continue;
                const double candidate = current_distance + static_cast<double>(current_vector.distance_to(node_vectors[next]));
                if (candidate < distances[next] && edge_clear(nodes[current], nodes[next], center_data, square_data, rectangles)) {
                    distances[next] = candidate; previous[next] = current;
                }
            }
        }
        Array path;
        if (previous[1] >= 0) {
            std::vector<std::int32_t> reverse;
            std::int32_t cursor = 1;
            for (std::size_t step = 0; step < count; ++step) {
                if (cursor <= 0) break;
                reverse.push_back(cursor); cursor = previous[cursor];
            }
            for (auto it = reverse.rbegin(); it != reverse.rend(); ++it) path.append(nodes[*it]);
        }
        Dictionary result; result["accepted"] = true; result["path"] = path; result["reason"] = "OK"; return result;
    }
};
void initialize_m99_navigation(ModuleInitializationLevel level) {
    if (level == MODULE_INITIALIZATION_LEVEL_SCENE) ClassDB::register_class<WarbeastNavigationM99>();
}
void uninitialize_m99_navigation(ModuleInitializationLevel) {}
}
extern "C" {
GDExtensionBool GDE_EXPORT warbeast_m99_navigation_library_init(GDExtensionInterfaceGetProcAddress get_proc_address,
    GDExtensionClassLibraryPtr library, GDExtensionInitialization *initialization) {
    godot::GDExtensionBinding::InitObject init(get_proc_address, library, initialization);
    init.register_initializer(godot::initialize_m99_navigation);
    init.register_terminator(godot::uninitialize_m99_navigation);
    init.set_minimum_library_initialization_level(godot::MODULE_INITIALIZATION_LEVEL_SCENE);
    return init.init();
}
}
