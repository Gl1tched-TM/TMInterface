// Documentation available at https://donadigo.com/tminterface/plugins/api
string error;
SimulationStateFile startStateFile;
array<SimulationState@> states;

int nextframe;
int stateNum;

void OnRunStep(SimulationManager@ simManager)
{
    if (nextframe > 1){
        nextframe -= 1;
    } else if (nextframe == 1){
        simManager.SetSpeed(0);
        nextframe = 0;
    }

    if (simManager.RaceTime < 0 and states.Length > 0) {
        states.Clear();
        stateNum = 0;
    }
    stateNum += 1;
    states.Resize(stateNum + 1);
    @states[stateNum] = simManager.SaveState();

}

void Render()
{
    SimulationManager@ simManager = GetSimulationManager();
    if (UI::Begin("Frame Advance 2")) {
        if (UI::Button("Forward",vec2(0,25))) {
            GetSimulationManager().SetSpeed(.2);
            nextframe = 1;

        }
        UI::SameLine();
        if (UI::Button("Backward",vec2(0,25))) {
            if (stateNum > 1) {
                stateNum -= 2;
                simManager.RewindToState(states[stateNum], false);
            }
            
        }
    }  
    UI::End();
}

void Main()
{
    log("Plugin started.");
}

void OnDisabled()
{
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Frame Advance v2";
    info.Author = "Author";
    info.Version = "v2.0.0";
    info.Description = "Allows you to advance and rewind frames.";
    return info;
}
