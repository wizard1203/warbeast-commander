#pragma once
// Complete synchronous body-resolution candidate. No Godot dependency, global
// state, threads, policy, authority writes, floating point or square roots.
// Input rows must already have the original unique textual-ID lexical order.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <set>
#include <unordered_map>
#include <utility>
#include <vector>

namespace warbeast_m94 {
constexpr std::size_t body_stride = 12;
constexpr std::size_t max_rows = 8192;
constexpr std::size_t max_conflict_pairs = 8192;
constexpr std::int32_t coordinate_limit = 32768;
constexpr std::int32_t radius_limit = 512;
constexpr std::int32_t step_limit = 64;
constexpr std::int32_t active_flag = 1;
constexpr std::int32_t static_flag = 2;
constexpr std::int32_t has_goal_flag = 4;
enum class Status : std::int32_t { ok = 0, unsupported = 1, dense_fallback = 2 };
struct Point { std::int32_t x = 0, y = 0; };
inline bool operator==(Point a, Point b) { return a.x == b.x && a.y == b.y; }
inline bool operator!=(Point a, Point b) { return !(a == b); }
inline Point operator+(Point a, Point b) { return {a.x + b.x, a.y + b.y}; }
inline Point operator-(Point a, Point b) { return {a.x - b.x, a.y - b.y}; }
inline Point operator*(Point a, std::int32_t k) { return {a.x*k,a.y*k}; }
inline std::int64_t squared(Point p) { return std::int64_t(p.x)*p.x + std::int64_t(p.y)*p.y; }
inline std::int64_t dot(Point a, Point b) { return std::int64_t(a.x)*b.x + std::int64_t(a.y)*b.y; }
inline std::int32_t magnitude(std::int32_t x) { return x < 0 ? -x : x; }
struct Bounds { std::int32_t x=0,y=0,width=0,height=0; };
struct Body {
    Point old,desired,goal,previous;
    std::int32_t radius=0,flags=0,layer=0,step=0;
    bool active() const { return (flags & active_flag) != 0; }
    bool fixed() const { return (flags & static_flag) != 0; }
    bool has_goal() const { return (flags & has_goal_flag) != 0; }
};
struct Result { Status status=Status::ok; std::vector<Point> positions; };
inline Result rejected(Status s=Status::unsupported) { Result r;r.status=s;return r; }
inline bool legal_coordinate(std::int32_t x) { return x>=-coordinate_limit && x<=coordinate_limit; }
inline bool inside(Point p, Bounds b, std::int32_t radius) {
    return p.x>=b.x+radius && p.x<=b.x+b.width-radius && p.y>=b.y+radius && p.y<=b.y+b.height-radius;
}
inline Point clamp_arena(Point p,Bounds b,std::int32_t radius) {
    return {std::min(b.x+b.width-radius,std::max(b.x+radius,p.x)),
        std::min(b.y+b.height-radius,std::max(b.y+radius,p.y))};
}
inline bool shares_layer(const Body &a,const Body &b) {
    return !(a.fixed() && b.fixed()) && a.layer==b.layer;
}
inline bool segments_overlap(Point a0,Point a1,Point b0,Point b1,std::int32_t separation) {
    if (separation>=0 && (std::max(a0.x,a1.x)+separation<=std::min(b0.x,b1.x)
        || std::max(b0.x,b1.x)+separation<=std::min(a0.x,a1.x))) return false;
    if (separation>=0 && (std::max(a0.y,a1.y)+separation<=std::min(b0.y,b1.y)
        || std::max(b0.y,b1.y)+separation<=std::min(a0.y,a1.y))) return false;
    const Point start=a0-b0;
    const Point velocity=(a1-a0)-(b1-b0);
    const std::int64_t v2=squared(velocity),r2=std::int64_t(separation)*separation;
    if (v2==0) return squared(start)<r2;
    const std::int64_t sv=dot(start,velocity);
    if (sv>=0) return squared(start)<r2;
    if (-sv>=v2) return squared(start+velocity)<r2;
    // Guarded coordinates and per-axis displacement <=64 keep these products
    // within signed int64. In particular initial out-of-arena jumps decline.
    return squared(start)*v2-sv*sv<r2*v2;
}
inline std::int32_t floor_cell(std::int32_t x) {
    constexpr std::int32_t cell=64;
    return x>=0 ? x/cell : -((-x+cell-1)/cell);
}
inline std::uint64_t cell_key(std::int32_t x,std::int32_t y) {
    return (std::uint64_t(std::uint32_t(x))<<32) | std::uint32_t(y);
}
inline bool build_neighbors(const std::vector<Body> &bodies,const std::vector<Point> &resolved,
    std::vector<std::vector<std::size_t>> &neighbors) {
    neighbors.assign(bodies.size(),{});
    if (bodies.size()<48) {
        for (std::size_t i=0;i<bodies.size();++i) if (bodies[i].active())
            for (std::size_t j=0;j<bodies.size();++j)
                if (i!=j && bodies[j].active() && shares_layer(bodies[i],bodies[j])) neighbors[i].push_back(j);
        return true;
    }
    std::unordered_map<std::uint64_t,std::vector<std::size_t>> bins;
    std::vector<std::vector<std::uint64_t>> cells(bodies.size());
    for (std::size_t i=0;i<bodies.size();++i) {
        const Body &b=bodies[i];if (!b.active()) continue;
        const auto xmin=floor_cell(std::min(b.old.x-b.step,resolved[i].x)-b.radius);
        const auto xmax=floor_cell(std::max(b.old.x+b.step,resolved[i].x)+b.radius);
        const auto ymin=floor_cell(std::min(b.old.y-b.step,resolved[i].y)-b.radius);
        const auto ymax=floor_cell(std::max(b.old.y+b.step,resolved[i].y)+b.radius);
        if (std::int64_t(xmax-xmin+1)*(ymax-ymin+1)>256) return false;
        for (auto x=xmin;x<=xmax;++x) for (auto y=ymin;y<=ymax;++y) {
            const auto key=cell_key(x,y);cells[i].push_back(key);bins[key].push_back(i);
        }
    }
    for (std::size_t i=0;i<bodies.size();++i) {
        if (!bodies[i].active() || bodies[i].fixed()) continue;
        for (const auto key:cells[i]) for (const auto j:bins[key]) {
            if (i==j || !shares_layer(bodies[i],bodies[j])) continue;
            neighbors[i].push_back(j);neighbors[j].push_back(i);
        }
    }
    for (auto &row:neighbors) { std::sort(row.begin(),row.end());row.erase(std::unique(row.begin(),row.end()),row.end()); }
    return true;
}
inline bool pair_overlaps(std::size_t a,std::size_t b,const std::vector<Body> &bodies,const std::vector<Point> &resolved) {
    return segments_overlap(bodies[a].old,resolved[a],bodies[b].old,resolved[b],bodies[a].radius+bodies[b].radius);
}
inline bool any_conflict(const std::vector<Body> &bodies,const std::vector<Point> &resolved,
    const std::vector<std::vector<std::size_t>> &neighbors) {
    for (std::size_t i=0;i<bodies.size();++i) if (bodies[i].active())
        for (const auto j:neighbors[i]) if (j>i && shares_layer(bodies[i],bodies[j]) && pair_overlaps(i,j,bodies,resolved)) return true;
    return false;
}
inline void append_candidate(std::vector<Point> &out,std::set<std::pair<std::int32_t,std::int32_t>> &seen,
    Point p,Point old,Bounds bounds,std::int32_t radius,std::int32_t step,bool allow_wait=false) {
    if (seen.count({p.x,p.y}) || (p==old && !allow_wait)) return;
    const Point delta=p-old;
    if (magnitude(delta.x)>step || magnitude(delta.y)>step || !inside(p,bounds,radius)) return;
    seen.insert({p.x,p.y});out.push_back(p);
}
inline std::vector<Point> candidates(Point old,Point preferred,Bounds bounds,std::int32_t radius,std::int32_t step) {
    std::vector<Point> out;
    std::set<std::pair<std::int32_t,std::int32_t>> seen;
    append_candidate(out,seen,preferred,old,bounds,radius,step);
    const Point delta=preferred-old;
    append_candidate(out,seen,old+Point{delta.x,0},old,bounds,radius,step);
    append_candidate(out,seen,old+Point{0,delta.y},old,bounds,radius,step);
    // Signed C++ integer division truncates toward zero, like the GD oracle.
    append_candidate(out,seen,old+Point{delta.x/2,delta.y/2},old,bounds,radius,step);
    std::vector<Point> directions={{1,0},{1,-1},{1,1},{0,-1},{0,1},{-1,0},{-1,-1},{-1,1}};
    std::sort(directions.begin(),directions.end(),[delta](Point a,Point b) {
        const auto da=dot(delta,a),db=dot(delta,b);
        if (da!=db) return da>db;
        return a.x==b.x ? a.y<b.y : a.x<b.x;
    });
    for (const auto distance:{step,std::max(1,step/2),1}) for (const auto direction:directions)
        append_candidate(out,seen,old+direction*distance,old,bounds,radius,step);
    append_candidate(out,seen,old,old,bounds,radius,step,true);
    return out;
}
inline bool try_alternative(std::size_t index,const std::vector<Body> &bodies,std::vector<Point> &resolved,
    Bounds bounds,const std::vector<std::vector<std::size_t>> &neighbors) {
    const Body &b=bodies[index];
    auto options=candidates(b.old,resolved[index],bounds,b.radius,b.step);
    std::sort(options.begin(),options.end(),[&b](Point a,Point c) {
        if (a==b.old || c==b.old) return c==b.old && a!=b.old;
        if (b.has_goal() && b.previous!=b.old && (a==b.previous)!=(c==b.previous)) return c==b.previous;
        const auto astep=std::max(magnitude(a.x-b.old.x),magnitude(a.y-b.old.y));
        const auto cstep=std::max(magnitude(c.x-b.old.x),magnitude(c.y-b.old.y));
        if (astep!=cstep) return astep>cstep;
        const auto ad=squared(b.goal-a),cd=squared(b.goal-c);
        if (ad!=cd) return ad<cd;
        return a.x==c.x ? a.y<c.y : a.x<c.x;
    });
    for (const auto point:options) {
        bool safe=true;
        for (const auto other:neighbors[index]) {
            if (!bodies[other].active() || !shares_layer(b,bodies[other])) continue;
            if (segments_overlap(b.old,point,bodies[other].old,resolved[other],b.radius+bodies[other].radius)) {safe=false;break;}
        }
        if (safe) {resolved[index]=point;return true;}
    }
    return false;
}
inline Result solve(const std::int32_t *words,std::size_t word_count,const std::int32_t *bound_words,
    std::size_t bound_count,std::int64_t maximum_step) {
    if (word_count%body_stride || word_count/body_stride>max_rows || (word_count && !words)
        || bound_count!=4 || !bound_words || maximum_step<0 || maximum_step>step_limit) return rejected();
    const Bounds bounds{bound_words[0],bound_words[1],bound_words[2],bound_words[3]};
    if (!legal_coordinate(bounds.x) || !legal_coordinate(bounds.y) || bounds.width<=0 || bounds.height<=0
        || bounds.width>2*coordinate_limit || bounds.height>2*coordinate_limit
        || !legal_coordinate(bounds.x+bounds.width) || !legal_coordinate(bounds.y+bounds.height)) return rejected();
    const auto count=word_count/body_stride;
    std::vector<Body> bodies;bodies.reserve(count);
    Result result;result.positions.reserve(count);
    for (std::size_t i=0;i<count;++i) {
        const auto *r=words+i*body_stride;
        Body b{{r[0],r[1]},{r[2],r[3]},{r[8],r[9]},{r[10],r[11]},r[4],r[5],r[6],r[7]};
        for (const auto field:{0,1,2,3,8,9,10,11}) if (!legal_coordinate(r[field])) return rejected();
        if (b.radius<0 || b.radius>radius_limit || b.flags<0 || (b.flags&~7)!=0
            || b.layer<0 || b.layer>1 || b.step<0 || b.step>maximum_step
            || bounds.width<2*b.radius || bounds.height<2*b.radius
            || (b.active() && !b.fixed() && !inside(b.old,bounds,b.radius))) return rejected();
        // Without HAS_GOAL, original get(steering_goal,desired) uses desired.
        if (!b.has_goal()) b.goal=b.desired;
        const Point delta=b.desired-b.old;
        const Point wanted{b.old.x+std::min(b.step,std::max(-b.step,delta.x)),b.old.y+std::min(b.step,std::max(-b.step,delta.y))};
        result.positions.push_back(b.active() && !b.fixed() ? clamp_arena(wanted,bounds,b.radius) : b.old);
        bodies.push_back(b);
    }
    std::vector<std::vector<std::size_t>> neighbors;
    if (!build_neighbors(bodies,result.positions,neighbors)) return rejected();
    if (!any_conflict(bodies,result.positions,neighbors)) return result;
    struct Pair {std::size_t left,right;};
    std::vector<Pair> pairs;
    std::vector<std::vector<std::size_t>> incident(count);
    for (std::size_t i=0;i<count;++i) if (bodies[i].active()) for (const auto j:neighbors[i]) {
        if (j<=i || !shares_layer(bodies[i],bodies[j])) continue;
        if (pairs.size()>=max_conflict_pairs) return rejected(Status::dense_fallback);
        const auto rank=pairs.size();pairs.push_back({i,j});incident[i].push_back(rank);incident[j].push_back(rank);
    }
    std::set<std::size_t> conflicts;
    for (std::size_t rank=0;rank<pairs.size();++rank) if (pair_overlaps(pairs[rank].left,pairs[rank].right,bodies,result.positions)) conflicts.insert(rank);
    const auto update=[&](std::size_t id) {
        for (const auto rank:incident[id]) {
            const auto p=pairs[rank];
            if (pair_overlaps(p.left,p.right,bodies,result.positions)) conflicts.insert(rank);
            else conflicts.erase(rank);
        }
    };
    std::vector<bool> frozen(count,false);
    const auto attempts=std::max<std::size_t>(1,count*count*2);
    for (std::size_t attempt=0;attempt<attempts;++attempt) {
        if (conflicts.empty()) return result;
        const auto p=pairs[*conflicts.begin()];
        if (!frozen[p.right]) {
            if (try_alternative(p.right,bodies,result.positions,bounds,neighbors)) {update(p.right);continue;}
            result.positions[p.right]=bodies[p.right].old;frozen[p.right]=true;update(p.right);continue;
        }
        if (!frozen[p.left]) {
            if (try_alternative(p.left,bodies,result.positions,bounds,neighbors)) {update(p.left);continue;}
            result.positions[p.left]=bodies[p.left].old;frozen[p.left]=true;update(p.left);continue;
        }
        break;
    }
    if (any_conflict(bodies,result.positions,neighbors))
        for (std::size_t i=0;i<count;++i) result.positions[i]=bodies[i].old;
    return result;
}
} // namespace warbeast_m94
