int min_time;
int max_time;
int time;
int bestTime;

float bestSpeed;
float best;
float minSpeed;
float velocity;
float currPos;

string currDirection;
array<string> direction = {"+X (Towards Blue Sign)","+Z (Right of Blue Sign)","-X (Towards Green Sign)","-Z (Left of Blue Sign)"};

bool freeWheeling;
bool optimizeTime;
bool optimizeSpeed;
void RenderEvalSettings()
{
    UI::Dummy(vec2(0,10));
    min_time = UI::InputTimeVar("Min Time","freewheel_min_time");
    max_time = UI::InputTimeVar("Max Time","freewheel_max_time");
    UI::TextDimmed("Set Max time after freewheel block to stop bruteforce.");

    UI::Dummy(vec2(0,15));
    if (UI::CheckboxVar("Optimize Time?", "freewheel_optimizetime")) {
    } else {
        string currDirection = GetVariableString("freewheel_currdirection");
        if (UI::BeginCombo("Direction", currDirection))
        {
            for (uint i = 0; i < direction.Length; i++)
            {
                const string directions = direction[i];
                if (UI::Selectable(directions, directions == currDirection)) {
                    SetVariable("freewheel_currdirection",directions);
                }
                
            }

            UI::EndCombo();
        }
        optimizeTime = false;
    }
    
    if (optimizeSpeed = UI::CheckboxVar("Optimize Speed?","freewheel_optimizespeed")) {
    } else {
        minSpeed = UI::SliderFloatVar("Min Speed (0 to disable)","freewheel_min_speed", 0.0f, 1000.0f);
    }
    
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
        if (!GetVariableBool("freewheel_optimizetime")) {
            if (raceTime >= min_time and !freeWheeling) {
                time = raceTime;
                if (GetVariableString("freewheel_currdirection") == direction[0] or GetVariableString("freewheel_currdirection") == direction[2]) {
                    currPos = posX;
                } else if (GetVariableString("freewheel_currdirection") == direction[1] or GetVariableString("freewheel_currdirection") == direction[3]) {
                    currPos = posZ;
                }
            }
        // track time
        } else {
            if (raceTime >= min_time and !freeWheeling) {
                time = raceTime;
                if (optimizeSpeed) {
                    bestSpeed = velocity;
                }
            }
        }
        
        
        //track currpos

        if (!GetVariableBool("freewheel_optimizetime") and raceTime >= min_time and freeWheeling) {
            if (optimizeSpeed) {
                bestSpeed = velocity;
                best = currPos;
                printBase();
                resp.Decision = BFEvaluationDecision::Accept;
                return resp;
            } else {
                best = currPos;
                printBase();
                resp.Decision = BFEvaluationDecision::Accept;
                return resp;
            }
        } else if (GetVariableBool("freewheel_optimizetime") and raceTime >= min_time and freeWheeling) {
            if (optimizeSpeed) {
                bestTime = time;
                print("Base time not freewheeled: " + Time::Format(time) + "s" + " | Best Speed: " + bestSpeed);
                resp.Decision = BFEvaluationDecision::Accept;
                return resp;
            } else {
                bestTime = time;
                print("Base time not freewheeled: " + Time::Format(time) + "s");
                resp.Decision = BFEvaluationDecision::Accept;
                return resp;
            }
        }

    
    // Searching phase

    } else if (raceTime >= min_time and freeWheeling) {
        // keep min speed
        if (minSpeed > 0 and !optimizeSpeed and velocity >= minSpeed) {
            if (GetVariableBool("freewheel_optimizetime")) {
                // optimize for time
                if (isBetter(simManager)) {
                    resp.Decision = BFEvaluationDecision::Accept;
                    resp.ResultFileStartContent = "# Best Time not freewheeled: " + Time::Format(time);
                    return resp;
                } else {
                    resp.Decision = BFEvaluationDecision::Reject;
                    return resp;
                }
            } else {
                // optimize for position
                if (isBetter(simManager)) {
                    resp.Decision = BFEvaluationDecision::Accept;
                    resp.ResultFileStartContent = "# Best Position not freewheeled: " + best;
                    return resp;
                } else{
                    print("cur position " + currPos + " best position " + best);
                    resp.Decision = BFEvaluationDecision::Reject;
                    return resp;
                }
            }
            
        } else if (optimizeSpeed) {
            // check if velocity is over bestSpeed
            if (isBetter(simManager)) {
                if (GetVariableBool("freewheel_optimizetime")) {
                    resp.Decision = BFEvaluationDecision::Accept;
                    resp.ResultFileStartContent = "# Best Time not freewheeled: " + Time::Format(time);
                    return resp;
                } else {
                    resp.Decision = BFEvaluationDecision::Accept;
                    resp.ResultFileStartContent = "# Best Position not freewheeled: " + best;
                    return resp;
                }
            } else {
                resp.Decision = BFEvaluationDecision::Reject;
            }
            
        } else {
            // optimize for time
            if (isBetter(simManager)) {
                if (GetVariableBool("freewheel_optimizetime")) {
                    resp.Decision = BFEvaluationDecision::Accept;
                    resp.ResultFileStartContent = "# Best Time not freewheeled: " + Time::Format(time);
                    return resp;
                } else {
                    resp.Decision = BFEvaluationDecision::Accept;
                    resp.ResultFileStartContent = "# Best position not freewheeled: " + best;
                    return resp;
                }
            } else {
                resp.Decision = BFEvaluationDecision::Reject;
                return resp;
            }
        }

        return resp;

    } else if (raceTime >= max_time and !freeWheeling) {
        //check for minimum speed
        if (minSpeed > 0) {
            if (velocity >= minSpeed) {
                resp.Decision = BFEvaluationDecision::Accept;
                return resp;
            } else {
                resp.Decision = BFEvaluationDecision::Reject;
                return resp;
            }
        }
        if (optimizeSpeed) {
            if (isBetter(simManager)) {
                resp.ResultFileStartContent = "# Best Position not freewheeled: " +best;
                resp.Decision = BFEvaluationDecision::Accept;
                return resp;
            }
        } else {
            resp.Decision = BFEvaluationDecision::Accept;
            print("Skipped freewheel!",Severity::Success);
            resp.ResultFileStartContent = "# Freewheel Skipped";
            simManager.SetSimulationTimeLimit(0.0);
            return resp;
        }
    }

    if (!GetVariableBool("freewheel_optimizetime")) {
        //tracking position
        if (info.Phase == BFPhase::Search and raceTime >= min_time and !freeWheeling) {
            if (GetVariableString("freewheel_currdirection") == direction[0] or GetVariableString("freewheel_currdirection") == direction[2]) {
                currPos = posX;
            } else if (GetVariableString("freewheel_currdirection") == direction[1] or GetVariableString("freewheel_currdirection") == direction[3]) {
                currPos = posZ;
            }
        }
    } else {
        //tracking time
        if (info.Phase == BFPhase::Search and raceTime >= min_time and !freeWheeling) {
            time = raceTime;
        }

    }
    

    return resp;
}

void OnSimulationBegin(SimulationManager@ simManager)
{
 
}

void printBase()
{
    string message = "Base";

    if (GetVariableString("freewheel_currdirection") == direction[0]) {
        message += " X not freewheeled: " + best + " (+X) (RaceTime: " + Time::Format(time) + ")";
    } else if (GetVariableString("freewheel_currdirection") == direction[1]) {
        message += " Z not freewheeled: " + best + " (+Z) (RaceTime: " + Time::Format(time) + ")";
    } else if (GetVariableString("freewheel_currdirection") == direction[2]) {
        message += " X not freewheeled: " + best + " (-X) (RaceTime: " + Time::Format(time) + ")";
    } else if (GetVariableString("freewheel_currdirection") == direction[3]) {
        message += " Z not freewheeled: " + best + " (-Z) (RaceTime: " + Time::Format(time) + ")";
    }

    if (optimizeSpeed) {
        message += " | Best Speed: " + bestSpeed;
    } else if (minSpeed > 0) {
        message += " | Min Speed";
    }

    print(message);
    
}

bool isBetter(SimulationManager@ simManager)
{
    //accept position improvements
    if (!GetVariableBool("freewheel_optimizetime")) {
        if (GetVariableString("freewheel_currdirection") == direction[0]) {
            // if cur pos is better  and velocity is better, accept.
            if (optimizeSpeed) {
                if (currPos >= best and velocity > bestSpeed) {
                    best = currPos;
                    bestSpeed = velocity;
                    print("Found better Position not freewheeled: " + Text::FormatFloat(best, "", 0, 10) + " (+X) (RaceTime: " + Time::Format(time) + ")" + " | Best Speed: " + bestSpeed, Severity::Success);
                    return true;
                }
            } else {
                if (currPos > best) {
                    best = currPos;
                    print("Found better Position not freewheeled: " + Text::FormatFloat(best, "", 0, 10) + " (+X) (RaceTime: " + Time::Format(time) + ")", Severity::Success);
                    return true;
                }
            }
        } else if (GetVariableString("freewheel_currdirection") == direction[1]) {
            if (optimizeSpeed) {
                if (currPos >= best and velocity > bestSpeed) {
                    best = currPos;
                    bestSpeed = velocity;
                    print("Found better Position not freewheeled: " + Text::FormatFloat(best, "", 0, 10) + " (+Z) (RaceTime: " + Time::Format(time) + ")" + " | Best Speed: " + bestSpeed, Severity::Success);
                    return true;
                }
            } else {
                if (currPos > best) {
                    best = currPos;
                    print("Found better Position not freewheeled: " + Text::FormatFloat(best, "", 0, 10) + " (+Z) (RaceTime: " + Time::Format(time) + ")", Severity::Success);
                    return true;
                }
            }
        } else if (GetVariableString("freewheel_currdirection") == direction[2]) {
            if (optimizeSpeed) {
                if (currPos >= best and velocity > bestSpeed) {
                    best = currPos;
                    bestSpeed = velocity;
                    print("Found better Position not freewheeled: " + best + " (-X) (RaceTime: " + Time::Format(time) + ")" + " | Best Speed: " + bestSpeed, Severity::Success);
                    return true;
                }
            } else {
                if (currPos > best) {
                    best = currPos;
                    print("Found better Position not freewheeled: " + best + " (-X) (RaceTime: " + Time::Format(time) + ")", Severity::Success);
                    return true;
                }
            }
        } else if (GetVariableString("freewheel_currdirection") == direction[3]) {
            if (optimizeSpeed) {
                if (currPos >= best and velocity > bestSpeed) {
                    best = currPos;
                    bestSpeed = velocity;
                    print("Found better Position not freewheeled: " + best + " (-Z) (RaceTime: " + Time::Format(time) + ")" + " | Best Speed: " + bestSpeed, Severity::Success);
                    return true;
                }
            } else {
                if (currPos > best) {
                    best = currPos;
                    print("Found better Position not freewheeled: " + best + " (-Z) (RaceTime: " + Time::Format(time) + ")", Severity::Success);
                    return true;
                }
            }
        }
    //accept time improvements
    } else {
        if (time > bestTime) {
            if (minSpeed > 0) {
                if (velocity >= minSpeed) {
                    print("Found more time not freewheeled: " + Time::Format(time) + "s" + " (Min Speed)", Severity::Success);
                    bestTime = time;
                    return true;
                } else {
                    return false;
                }
            } else if (optimizeSpeed and velocity >= bestSpeed) {
                print("Found more time not freewheeled: " + Time::Format(time) + "s" + " | Best Speed: " + bestSpeed, Severity::Success);
                bestSpeed = velocity;
                bestTime = time;
                return true;
            // if min speed is not used, still accept
            } else {
                print("Found more time not freewheeled: " + Time::Format(time) + "s", Severity::Success);
                bestTime = time;
                return true;
            }
        }
    }
    

    return false;
}


void Main()
{
    RegisterVariable("freewheel_min_time",0);
    RegisterVariable("freewheel_max_time",0);
    RegisterVariable("freewheel_min_speed",0);
    RegisterVariable("freewheel_optimizespeed",false);
    RegisterVariable("freewheel_optimizetime",false);
    RegisterVariable("freewheel_currdirection",direction[0]);
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
    info.Version = "v2.1.2";
    info.Description = "Searches for the least amount of freewheel time.";
    return info;
}
