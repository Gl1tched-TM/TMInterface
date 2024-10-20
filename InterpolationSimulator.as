// Documentation available at https://donadigo.com/tminterface/plugins/api

array<SimulationState@> raceStates;
uint stateNumber = 0;
int saveEvery = 10;
bool start = false;
bool playback = false;
bool Pause = false;
bool backwards = false;
int pointInRace;
bool slider = false;
bool freeze = false;

void freezeCar(SimulationManager@ simManager) {
    auto@ const dyna = simManager.Dyna.RefStateCurrent;
    dyna.LinearSpeed = vec3(0);
    dyna.AngularSpeed = vec3(0);
}

void OnRunStep(SimulationManager@ simManager)
{
    int raceTime = simManager.RaceTime;
    bool finished = simManager.PlayerInfo.RaceFinished;

    if (start) {
        if (finished) {
            start = false;
        }
        else if (raceTime >= 0) {
            freeze = false;
            if (raceTime % saveEvery == 0 and !Pause) {
                stateNumber += 1;
                raceStates.Add(simManager.SaveState());
            }
        }
    }

    if (playback and raceTime >= 0 and !finished and !Pause) {
        if (raceTime % saveEvery == 0) {
            if (backwards) {
                simManager.RewindToState(raceStates[stateNumber], false);
                stateNumber -= 1;
            } else {
                simManager.RewindToState(raceStates[stateNumber], false);
                stateNumber += 1;
            }
            if (freeze) {
                freezeCar(simManager);
            }
        }
        if (stateNumber == raceStates.Length - 1) {
            playback = false;
            freeze = false;
        }
    }

    if (raceTime == 0) {
        stateNumber = 0;
    }
    if (stateNumber == 0 and backwards) {
        backwards = false;
    }
}

void Render()
{
    SimulationManager@ simManager = GetSimulationManager();
    if (UI::Begin("Interpolation Simulator")) {
        if (UI::Button("Start") and saveEvery != 0) {
            freeze = false;
            start = true;
            simManager.GiveUp();
            stateNumber = 0;
            raceStates.Clear();
            backwards = false;
        }
        UI::SameLine();
        if (UI::Button(Pause ? "Unpause" : "Pause")) {
            Pause = !Pause;
        }
        UI::SameLine();
        if (UI::Button("Play Back")) {
            if (raceStates.Length > 0) {
                playback = true;
                start = false;
                simManager.GiveUp();
                stateNumber = 0;
                freeze = true;
            }
        }
        UI::SameLine();
        if (UI::Button("Clear States")) {
            if (raceStates.Length > 0) {
                raceStates.Clear();
                log("States Cleared.");
                playback = false;
                start = false;
                freeze = false;
                backwards = false;
            }
            else {
                log("No states saved.");
            }
        }
        if (playback) {
            if (UI::Button(backwards ? "Replay Forward" : "Replay Backwards")) {
                backwards = !backwards;
            }
        }
        
        UI::Text("Save State every X seconds:");
        saveEvery = UI::InputTime("##Seconds", saveEvery);
        if (playback) {
            freeze = UI::Checkbox("Freeze Car", freeze);
        }
        if (saveEvery < 10) {
            saveEvery = 10;
        }
    }

    UI::End();
}

void Main()
{
    log("Plugin started.");
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Interpolation Simulator";
    info.Author = "Gl1tch3D";
    info.Version = "v2.1.0";
    info.Description = "Simulates interpolation";
    return info;
}
