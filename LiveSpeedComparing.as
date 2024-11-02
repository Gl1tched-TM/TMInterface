// Documentation available at https://donadigo.com/tminterface/plugins/api
float currSpeed;
float replaySpeed;
float diff;
array<float> speedStates;
bool validated = false;
SimulationManager@ simManager = GetSimulationManager();

void OnRunStep(SimulationManager@ simManager)
{
    if (simManager.RaceTime < 0) {
		currSpeed = 0;
		replaySpeed = 0;
		diff = 0;
		return;
    }

    currSpeed = simManager.Dyna.CurrentState.LinearSpeed.Length() * 3.6;
	uint index = simManager.RaceTime / 10;
    if (index < speedStates.Length) {
        replaySpeed = speedStates[index];
    } else {
		replaySpeed = 0;
	}
    diff = currSpeed - replaySpeed;
}

void OnSimulationBegin(SimulationManager@ simManager)
{
    speedStates.Clear();
}

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    if (simManager.RaceTime >= 0) {
        speedStates.Add(simManager.Dyna.CurrentState.LinearSpeed.Length() * 3.6);
    }
}

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult result)
{
    validated = true;
}

void Render()
{
    if (UI::Begin("Live Speed Comparing")) {
        if (validated) {
            UI::Text("Current Speed: " + currSpeed);
			UI::Text("Replay Speed: " + replaySpeed);
            UI::Text("Difference: " + diff);
        } else {
            UI::Text("Validate a replay to compare speed.");
        }
    }
    UI::End();
}

void Main()
{
    log("Please validate a replay to compare speed.");
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Live Speed Comparing";
    info.Author = "Gl1tch3D";
    info.Version = "v1.0.0";
    info.Description = "Compares current vehicle speed against validated replay speed.";
    return info;
}
