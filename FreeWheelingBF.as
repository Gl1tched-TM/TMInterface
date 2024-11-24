// Documentation available at https://donadigo.com/tminterface/plugins/api
int min_time;
int max_time;
int timeNotFreeWheeled;

void RenderEvalSettings()
{
    min_time = UI::InputTime("Min Time",min_time);
    max_time = UI::InputTime("Max Time",max_time);
}

int bestTime = -1;

BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
{

    int raceTime = simManager.RaceTime;
    bool freeWheel = simManager.get_SceneVehicleCar().IsFreeWheeling;
    SimulationState@ stateRewind;

    auto resp = BFEvaluationResponse();
    if (info.Phase == BFPhase::Initial) {
        if (simManager.PlayerInfo.RaceFinished or raceTime >= max_time) {
            print("Base: " + Time::Format(timeNotFreeWheeled));
            bestTime = timeNotFreeWheeled;
            resp.Decision = BFEvaluationDecision::Accept;
            timeNotFreeWheeled = 0;
        }
    } else if (raceTime >= max_time) {
        if (timeNotFreeWheeled > bestTime) {
            resp.Decision = BFEvaluationDecision::Accept;
            print("New time: " + Time::Format(timeNotFreeWheeled), Severity::Success);
            resp.ResultFileStartContent = "# Found more non-free-wheel time: " + Time::Format(timeNotFreeWheeled);
            bestTime = timeNotFreeWheeled;
            timeNotFreeWheeled = 0;
        } else {
            resp.Decision = BFEvaluationDecision::Reject;
            timeNotFreeWheeled = 0;
        }
    }

    if (info.Phase == BFPhase::Initial and raceTime >= min_time and !freeWheel) {
        timeNotFreeWheeled += 10;
        //print("Initial: " + timeNotFreeWheeled);
    }
    
    if (info.Phase == BFPhase::Search and raceTime >= min_time and !freeWheel) {
        timeNotFreeWheeled += 10;
        //print("Search: " + timeNotFreeWheeled + " (Base: " + bestTime + ")");
    } else if (info.Phase == BFPhase::Search and raceTime >= max_time) {
        resp.Decision = BFEvaluationDecision::Reject;
        //print("didn't improve");
        timeNotFreeWheeled = 0;
    }
    return resp;
}

void Main()
{
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
    info.Version = "v1.0.0";
    info.Description = "Searches for the least amount of freewheel time.";
    return info;
}
