int min_time;
int max_time;
int timeNotFreeWheeled;
int time;
float best;
float minSpeed;
float velocity;
float currPos;
string currDirection;
array<string> direction = {"+X (Towards Blue Sign)","+Z (Right of Blue Sign)","-X (Towards Green Sign)","-Z (Left of Blue Sign)"};
bool freeWheeling;
void RenderEvalSettings()
{
    UI::Dummy(vec2(0,10));
    min_time = UI::InputTimeVar("Min Time","freewheel_min_time");
    max_time = UI::InputTimeVar("Max Time","freewheel_max_time");
    UI::TextDimmed("Set Max time after freewheel block to stop bruteforce.");


    UI::Dummy(vec2(0,15));
    if (UI::BeginCombo("Direction", currDirection))
    {
        for (uint i = 0; i < direction.Length; i++)
        {
            const string directions = direction[i];
            if (UI::Selectable(directions, directions == currDirection)) {
                currDirection = directions;
            }
            
        }

        UI::EndCombo();
    }
    minSpeed = UI::SliderFloatVar("Min Speed (0 to disable)","freewheel_min_speed", 0.0f, 1000.0f);

}


BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
{
    int raceTime = simManager.RaceTime;
    
    freeWheeling = simManager.get_SceneVehicleCar().IsFreeWheeling;
    float posX = simManager.Dyna.CurrentState.Location.Position.x;
    float posZ = simManager.Dyna.CurrentState.Location.Position.z;
    velocity = simManager.Dyna.CurrentState.LinearSpeed.Length() * 3.6;

    auto resp = BFEvaluationResponse();
    if (info.Phase == BFPhase::Initial) {
        //set currpos
        if (raceTime >= min_time and !freeWheeling) {
            time = raceTime;
            if (currDirection == direction[0] or currDirection == direction[2]) {
                currPos = posX;
            } else if (currDirection == direction[1] or currDirection == direction[3]) {
                currPos = posZ;
            }
        }
        //track currpos
        if (raceTime >= min_time) {
            if (freeWheeling) {
                if (currDirection == direction[0]) {
                    best = currPos;
                    print("Base X not freewheeled: " + best + " (+X) (RaceTime: " + Time::Format(time) + ")");
                    resp.Decision = BFEvaluationDecision::Accept;
                    return resp;
                } else if (currDirection == direction[1]) {
                    best = currPos;
                    print("Base X not freewheeled: " + best + " (+Z) (RaceTime: " + Time::Format(time) + ")");
                    resp.Decision = BFEvaluationDecision::Accept;
                    return resp;
                } else if (currDirection == direction[2]) {
                    best = currPos;
                    print("Base Z not freewheeled: " + best + " (-X) (RaceTime: " + Time::Format(time) + ")");
                    resp.Decision = BFEvaluationDecision::Accept;
                    return resp;
                } else if (currDirection == direction[3]) {
                    best = currPos;
                    print("Base Z not freewheeled: " + best + " (-Z) (RaceTime: " + Time::Format(time) + ")");
                    resp.Decision = BFEvaluationDecision::Accept;
                    return resp;
                }
            }
        }


    } else if (raceTime >= min_time and freeWheeling) {
        if (isBetter(simManager)) {
            if (minSpeed > 0) {
                if (velocity >= minSpeed) {
                    resp.Decision = BFEvaluationDecision::Accept;
                    return resp;
                } else {
                    resp.Decision = BFEvaluationDecision::Reject;
                }
            }
            resp.Decision = BFEvaluationDecision::Accept;
            return resp;
        } else {
            resp.Decision = BFEvaluationDecision::Reject;
        }

        return resp;

    } else if (raceTime >= max_time and !freeWheeling) {
        if (minSpeed > 0) {
            if (velocity >= minSpeed) {
                resp.Decision = BFEvaluationDecision::Accept;
                return resp;
            } else {
                resp.Decision = BFEvaluationDecision::Reject;
                return resp;
            }
        }
        resp.Decision = BFEvaluationDecision::Accept;
        print("Skipped freewheel!",Severity::Success);
        resp.ResultFileStartContent = "# Freewheel Skipped";
        simManager.SetSimulationTimeLimit(0.0);
        return resp;
    }

    if (info.Phase == BFPhase::Search and raceTime >= min_time and !freeWheeling) {
        if (currDirection == direction[0] or currDirection == direction[2]) {
            currPos = posX;
        } else if (currDirection == direction[1] or currDirection == direction[3]) {
            currPos = posZ;
        }
    }

    return resp;
}

void OnSimulationBegin(SimulationManager@ simManager)
{
    if (minSpeed > 0) {
        print("Speed condition set to " + minSpeed);
    }
}

bool isBetter(SimulationManager@ simManager)
{
    
    if (currDirection == direction[0]) {
        if (currPos > best) {
            best = currPos;
            print("Best Position not freewheeled: " + best + " (RaceTime: " + Time::Format(time) + ")", Severity::Success);
            return true;
        }
    } else if (currDirection == direction[1]) {
        if (currPos < best) {
            best = currPos;
            print("Best Position not freewheeled: " + best + " (RaceTime: " + Time::Format(time) + ")", Severity::Success);
            return true;
        }
    } else if (currDirection == direction[2]) {
        if (currPos > best) {
            best = currPos;
            print("Best Position not freewheeled: " + best + " (RaceTime: " + Time::Format(time) + ")", Severity::Success);
            return true;
        }
    } else if (currDirection == direction[3]) {
        if (currPos < best) {
            best = currPos;
            print("Best Position not freewheeled: " + best + " (RaceTime: " + Time::Format(time) + ")", Severity::Success);
            return true;
        }
    }

    return false;
}


void Main()
{
    RegisterVariable("freewheel_min_time",0);
    RegisterVariable("freewheel_max_time",0);
    RegisterVariable("freewheel_min_speed",0);
    min_time = uint(Math::Max(0,int(GetVariableDouble("freewheel_min_time"))));
    max_time = uint(Math::Max(0,int(GetVariableDouble("freewheel_max_time"))));
    minSpeed = uint(Math::Max(0,float(GetVariableDouble("freewheel_min_speed"))));
    SetVariable("freewheel_min_time",min_time);
    SetVariable("freewheel_max_time",max_time);
    SetVariable("freewheel_min_speed",minSpeed);
    RegisterBruteforceEvaluation("freewheel", "Free Wheeling", OnEvaluate, RenderEvalSettings);
    log("Plugin started.");
}

void OnDisabled()
{
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Free-wheel BF";
    info.Author = "Gl1tch3D";
    info.Version = "v2.0.1";
    info.Description = "Searches for the least amount of freewheel time.";
    return info;
}
