#include "body_resolver_core.hpp"
#include <cassert>
#include <cstdint>
#include <iostream>
#include <vector>
using warbeast_m94::Point;
using warbeast_m94::Status;
using warbeast_m94::segments_overlap;

static void add(std::vector<std::int32_t> &rows,Point old,Point wanted,std::int32_t radius=8,
    std::int32_t flags=1,std::int32_t layer=0,std::int32_t step=8,Point goal={0,0},Point previous={0,0}) {
    if (!(flags&4)) goal=wanted;
    rows.insert(rows.end(),{old.x,old.y,wanted.x,wanted.y,radius,flags,layer,step,goal.x,goal.y,previous.x,previous.y});
}
static warbeast_m94::Result solve(const std::vector<std::int32_t> &rows,std::int32_t step=8) {
    const std::int32_t bounds[]={0,0,4096,4096};
    return warbeast_m94::solve(rows.empty()?nullptr:rows.data(),rows.size(),bounds,4,step);
}
int main() {
    assert(!segments_overlap({10,10},{20,10},{10,26},{20,26},16)); // touching legal
    assert(segments_overlap({10,10},{20,10},{10,25},{20,25},16));
    assert(segments_overlap({100,100},{120,100},{120,100},{100,100},16)); // swept swap
    assert(!segments_overlap({100,100},{108,100},{100,130},{108,130},16));
    assert(solve({}).status==Status::ok && solve({}).positions.empty());
    std::vector<std::int32_t> rows;
    add(rows,{100,100},{300,100});
    auto result=solve(rows);assert(result.status==Status::ok && result.positions[0]==(Point{108,100}));
    rows.clear();add(rows,{100,100},{300,100},8,0);
    result=solve(rows);assert(result.status==Status::ok && result.positions[0]==(Point{100,100}));
    rows.clear();add(rows,{100,100},{300,100},8,3);
    result=solve(rows);assert(result.positions[0]==(Point{100,100}));
    rows.clear();add(rows,{100,100},{108,100});add(rows,{124,100},{116,100});
    result=solve(rows);assert(result.status==Status::ok);
    assert(!segments_overlap({100,100},result.positions[0],{124,100},result.positions[1],16));
    rows.clear();add(rows,{100,100},{108,100},8,1,0);add(rows,{100,100},{108,100},8,1,1);
    result=solve(rows);assert(result.positions[0]==(Point{108,100}) && result.positions[1]==(Point{108,100}));
    rows.clear();add(rows,{100,100},{100,100},20,3,0,0);add(rows,{100,100},{100,100},20,3,0,0);
    result=solve(rows);assert(result.status==Status::ok && result.positions[0]==(Point{100,100}));
    rows.clear();add(rows,{100,100},{108,100},8,1,0,0);add(rows,{110,100},{118,100},8,1,0,0);
    result=solve(rows);assert(result.positions[0]==(Point{100,100}) && result.positions[1]==(Point{110,100})); // final all wait
    // >=48 activates the identical 64-cell conservative swept envelope graph.
    rows.clear();for(int i=0;i<64;++i)add(rows,{100+(i%8)*40,100+(i/8)*40},{108+(i%8)*40,100+(i/8)*40});
    result=solve(rows);assert(result.status==Status::ok && result.positions.size()==64);
    for(std::size_t i=0;i<64;++i)assert(result.positions[i]==(Point{108+int(i%8)*40,100+int(i/8)*40}));
    // Guarded malformed inputs decline; the GD adapter executes the full oracle.
    rows.clear();add(rows,{0,0},{100,100});assert(solve(rows).status==Status::unsupported);
    rows.clear();add(rows,{100,100},{108,100},-1);assert(solve(rows).status==Status::unsupported);
    rows.clear();add(rows,{100,100},{108,100});rows[6]=2;assert(solve(rows).status==Status::unsupported);
    rows.clear();add(rows,{32769,100},{108,100});assert(solve(rows).status==Status::unsupported);
    assert(solve({},65).status==Status::unsupported);
    rows={1};assert(solve(rows).status==Status::unsupported);
    // Negative floor and positive half truncation helpers are explicit.
    assert(warbeast_m94::floor_cell(-1)==-1 && warbeast_m94::floor_cell(-64)==-1 && warbeast_m94::floor_cell(-65)==-2);
    std::cout<<"M94 pure body smoke passed; not a Godot/oracle/performance qualification\n";
}
