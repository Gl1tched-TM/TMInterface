int min_time;
int max_time;
int timeNotFreeWheeled;
int time;

bool freeWheeling;
void RenderEvalSettings()
{
    min_time = UI::InputTime("Min Time",min_time);
    max_time = UI::InputTime("Max Time",max_time);
}

int bestTime = -1;

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
{
    int raceTime = simManager.RaceTime;
    SimulationState@ stateRewind;

    freeWheeling = simManager.get_SceneVehicleCar().IsFreeWheeling;

    auto resp = BFEvaluationResponse();
    if (info.Phase == BFPhase::Initial) {
        if (raceTime >= min_time and !freeWheeling) {
            timeNotFreeWheeled += 10;
        }
        if (raceTime >= max_time) {
            print("Base: " + Time::Format(timeNotFreeWheeled) + "s (Time: " + Time::Format(time) +")");
            bestTime = timeNotFreeWheeled;
            resp.Decision = BFEvaluationDecision::Accept;
            timeNotFreeWheeled = 0;
        }
    } else if (raceTime >= max_time) {
        if (timeNotFreeWheeled > bestTime) {
            resp.Decision = BFEvaluationDecision::Accept;
            print("New time: " + Time::Format(timeNotFreeWheeled) + "s (Time: " + Time::Format(time) +")", Severity::Success);
            resp.ResultFileStartContent = "# Found more non-free-wheel time: " + Time::Format(timeNotFreeWheeled);
            bestTime = timeNotFreeWheeled;
            timeNotFreeWheeled = 0;
        } else {
            resp.Decision = BFEvaluationDecision::Reject;
            timeNotFreeWheeled = 0;
        }
    }
    
    if (info.Phase == BFPhase::Search and raceTime >= min_time and !freeWheeling) {
        timeNotFreeWheeled += 10;
        //print("Search: " + timeNotFreeWheeled + " (Base: " + bestTime + ")");
    }

    if (!freeWheeling and raceTime >= min_time) {
        time = simManager.RaceTime;
    }
    
    return resp;
}



void Main()
{
    RegisterVariable("freewheel_min_time",0);
    RegisterVariable("freewheel_max_time",0);
    min_time = uint(Math::Max(0,int(GetVariableDouble("freewheel_min_time"))));
    max_time = uint(Math::Max(0,int(GetVariableDouble("freewheel_max_time"))));
    SetVariable("freewheel_min_time",min_time);
    SetVariable("freewheel_max_time",max_time);
    RegisterBruteforceEvaluation("freewheel", "Free Wheel Time", OnEvaluate, RenderEvalSettings);
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
    info.Version = "v1.0.1";
    info.Description = "Searches for the least amount of freewheel time.";
    return info;
}
