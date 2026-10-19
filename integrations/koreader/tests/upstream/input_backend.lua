-- Runs the actual patched Android backend, mocking only the unavailable Android/FFI boundary.
-- Also works as a Busted spec when exported into koreader-base/spec/unit.
local function harness(path)
    local C = {EV_ABS=3, EV_SYN=0, EV_MSC=4, SYN_REPORT=0, ABS_MT_SLOT=47,
        ABS_MT_TOOL_TYPE=55, ABS_MT_TRACKING_ID=57, ABS_MT_POSITION_X=53, ABS_MT_POSITION_Y=54,
        AMOTION_EVENT_ACTION_MASK=255, AMOTION_EVENT_ACTION_POINTER_INDEX_MASK=65280,
        AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT=8, AMOTION_EVENT_ACTION_DOWN=0,
        AMOTION_EVENT_ACTION_UP=1, AMOTION_EVENT_ACTION_MOVE=2, AMOTION_EVENT_ACTION_CANCEL=3,
        AMOTION_EVENT_ACTION_POINTER_DOWN=5, AMOTION_EVENT_ACTION_POINTER_UP=6,
        APP_CMD_LOST_FOCUS=7, LOOPER_ID_INPUT=2, AINPUT_EVENT_TYPE_MOTION=2, EINTR=4}
    local packets, completed = {}, 0
    local android = {app={destroyRequested=0}, lib={}, ignored=false}
    android.isTouchscreenIgnored = function() return android.ignored end
    local lib = android.lib
    lib.AMOTION_EVENT_TOOL_TYPE_STYLUS, lib.AMOTION_EVENT_TOOL_TYPE_ERASER = 2, 4
    lib.ALooper_pollOnce = function() return C.LOOPER_ID_INPUT end
    lib.AInputQueue_getEvent = function(_, pointer)
        if #packets == 0 then return -1 end
        pointer[0] = table.remove(packets,1);return 0
    end
    lib.AInputQueue_preDispatchEvent = function() return 0 end
    lib.AInputEvent_getType = function() return C.AINPUT_EVENT_TYPE_MOTION end
    lib.AInputQueue_finishEvent = function() completed = completed + 1 end
    lib.AMotionEvent_getAction = function(e) return e.action end
    lib.AMotionEvent_getEventTime = function() return 1000000000 end
    lib.AMotionEvent_getPointerCount = function(e) return #e.pointers end
    lib.AMotionEvent_getPointerId = function(e,i) return e.pointers[i+1].id end
    lib.AMotionEvent_getToolType = function(e,i) return e.pointers[i+1].tool end
    lib.AMotionEvent_getX = function(e,i) return e.pointers[i+1].x or 10 end
    lib.AMotionEvent_getY = function(e,i) return e.pointers[i+1].y or 20 end
    lib.AMotionEvent_getHistorySize = function() return 0 end
    local fake_ffi = {C=C,new=function() return {[0]=0} end,cast=function(_,v) return v end}
    local names, old = {'ffi','android','ffi/posix_h','ffi/linux_input_h'}, {}
    for _, name in ipairs(names) do old[name]=package.loaded[name] end
    package.loaded.ffi, package.loaded.android = fake_ffi, android
    package.loaded['ffi/posix_h'], package.loaded['ffi/linux_input_h'] = true, true
    local ok, input = pcall(dofile,path)
    for _, name in ipairs(names) do package.loaded[name]=old[name] end
    assert(ok,input)
    local function send(action,pointers)
        packets[1]={action=action,pointers=pointers or {{id=0,tool=1}}}
        local available,events=input.waitForEvent(0,0)
        return available and events or {}
    end
    local function has(events,code,value)
        for _,e in ipairs(events) do if e.code==code and e.value==value then return true end end
        return false
    end
    return input,send,has,C,android,function() return completed end
end
local tests = {
    {'default finger/stylus/eraser mapping remains intact', function(path)
        local _,send,has,C=harness(path)
        for _,pair in ipairs({{1,0},{2,1},{4,2}}) do
            assert(has(send(0,{{id=0,tool=pair[1]}}),C.ABS_MT_TOOL_TYPE,pair[2]))
            assert(has(send(1),C.ABS_MT_TRACKING_ID,-1))
        end
    end},
    {'claimed complete gestures produce no reader events but finish the native queue', function(path)
        local input,send,_,_,_,completed=harness(path)
        input.setMotionEventFilter(function() return true end)
        for _,action in ipairs({0,2,1,3}) do assert(#send(action)==0) end
        assert(completed()==4)
    end},
    {'tool overrides reach both primary and secondary pointer downs', function(path)
        local input,send,has,C=harness(path)
        input.setMotionEventFilter(function() return false,1 end)
        assert(has(send(0),C.ABS_MT_TOOL_TYPE,1))
        assert(has(send(5+256,{{id=0,tool=1},{id=8,tool=1}}),C.ABS_MT_SLOT,8))
        assert(has(send(5+256,{{id=0,tool=1},{id=8,tool=1}}),C.ABS_MT_TOOL_TYPE,1))
    end},
    {'mixed pointers retain native tool classification without an override', function(path)
        local _,send,has,C=harness(path)
        assert(has(send(0),C.ABS_MT_TOOL_TYPE,0))
        assert(has(send(5+256,{{id=0,tool=1},{id=8,tool=2}}),C.ABS_MT_TOOL_TYPE,1))
        local moves=send(2,{{id=8,tool=2},{id=0,tool=1}})
        assert(has(moves,C.ABS_MT_SLOT,8) and has(moves,C.ABS_MT_SLOT,0))
    end},
    {'cancel clears active pointer state before subsequent motion', function(path)
        local _,send,has,C=harness(path)
        send(0)
        assert(has(send(3),C.APP_CMD_LOST_FOCUS,42))
        assert(not has(send(2),C.ABS_MT_POSITION_X,10))
    end},
    {'restoring the previous hook restores its behavior', function(path)
        local input,send=harness(path)
        local original=function() return true end
        input.setMotionEventFilter(original)
        local saved=input.getMotionEventFilter()
        input.setMotionEventFilter(function() return false end)
        assert(#send(0)>0)
        input.setMotionEventFilter(saved)
        assert(input.getMotionEventFilter()==original and #send(0)==0)
        input.setMotionEventFilter(nil)
        assert(#send(0)>0)
    end},
    {'ignored touchscreen still produces no input events', function(path)
        local input,send,_,_,android=harness(path)
        android.ignored=true
        input.setMotionEventFilter(function() return false,1 end)
        assert(#send(0)==0)
    end},
}
if type(describe)=='function' then
    describe('Android native motion filter',function()
        for _,case in ipairs(tests) do it(case[1],function() case[2]('ffi/input_android.lua') end) end
    end)
else
    for _,case in ipairs(tests) do case[2](assert(arg[1]));print('ok - '..case[1]) end
    print('Passed '..#tests..' actual Android backend scenarios with simulated platform events')
end
