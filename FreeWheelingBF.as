int min_time;
int max_time;
int time;
int bestTime;
int min_wheels;

float bestSpeed;
float best;
float minSpeed;
float velocity;
float currPos;

string currDirection;
array<string> direction = {"+X (Towards Blue Sign)","+Z (Right of Blue Sign)","-X (Towards Green Sign)","-Z (Left of Blue Sign)"};

bool optimizeTime;
bool optimizeSpeed;
bool frWheel;
bool flWheel;
bool brWheel;
bool blWheel;

void RenderEvalSettings()
{
    UI::Dummy(vec2(0,10));
    min_time = UI::InputTimeVar("Min Time","freewheel_min_time");
    max_time = UI::InputTimeVar("Max Time","freewheel_max_time");
    UI::TextDimmed("Set Max time after freewheel block to stop bruteforce.");

    UI::Dummy(vec2(0,15));

    optimizeTime = UI::CheckboxVar("Optimize Time?", "freewheel_optimizetime");
    if (!optimizeTime) {
        currDirection = GetVariableString("freewheel_currdirection");
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

    optimizeSpeed = UI::CheckboxVar("Optimize Speed?", "freewheel_optimizespeed");
    if (!optimizeSpeed) {
        minSpeed = UI::SliderFloatVar("Min Speed (0 to disable)","freewheel_min_speed", 0.0f, 1000.0f);
    }

    UI::Dummy(vec2(0,15));
    UI::Separator();
    UI::Dummy(vec2(0,15));
    UI::Text("Wheel Conditions:");

    min_wheels = UI::SliderIntVar("Minimum Wheels on ground (0 to disable)","freewheel_min_wheels", 0, 4);

    UI::Dummy(vec2(0,10));

    UI::BeginDisabled(min_wheels > 0);
    flWheel = UI::Checkbox("Front Left",flWheel);
    UI::SameLine();
    frWheel = UI::Checkbox("Front Right",frWheel);

    blWheel = UI::Checkbox("Back Left",blWheel);
    UI::SameLine();
    brWheel = UI::Checkbox("Back Right",brWheel);
    UI::EndDisabled();

    UI::TextDimmed("Check any of the boxes to ensure those wheels stay on the ground.");
}


BFEvaluationResponse@ OnEvaluate(SimulationManager@ simManager, const BFEvaluationInfo&in info)
{
    int raceTime = simManager.RaceTime;

    bool freeWheeling = simManager.SceneVehicleCar.IsFreeWheeling;
    float posX = simManager.Dyna.CurrentState.Location.Position.x;
    float posZ = simManager.Dyna.CurrentState.Location.Position.z;
    velocity = simManager.Dyna.CurrentState.LinearSpeed.Length() * 3.6;

    auto resp = BFEvaluationResponse();

    switch (info.Phase) {
    case BFPhase::Initial:
        if (raceTime < min_time) {
            break;
        }

        if (freeWheeling) {
            if (optimizeTime) {
                bestTime = time;
                if (info.Iterations == 0) {
                    printBase();
                }
            } else {
                if (optimizeSpeed) {
                    bestSpeed = velocity;
                }
                best = currPos;
                if (info.Iterations == 0) {
                    printBase();
                }
            }
            resp.Decision = BFEvaluationDecision::Accept;
        } else {
            // track time
            time = raceTime;
            if (optimizeTime) {
                if (optimizeSpeed) {
                    bestSpeed = velocity;
                }
            } else {
                if (currDirection == direction[0] or currDirection == direction[2]) {
                    currPos = posX;
                } else if (currDirection == direction[1] or currDirection == direction[3]) {
                    currPos = posZ;
                }
            }
        }

        break;
    case BFPhase::Search:
        if (raceTime < min_time) {
            break;
        }

        if (freeWheeling) {
            if (isBetter(simManager)) {
                resp.Decision = BFEvaluationDecision::Accept;
            } else {
                resp.Decision = BFEvaluationDecision::Reject;
            }
            break;
        }

        if (raceTime == max_time) {
            // check for minimum speed
            if (minSpeed > 0) {
                if (velocity >= minSpeed) {
                    resp.Decision = BFEvaluationDecision::Accept;
                } else {
                    resp.Decision = BFEvaluationDecision::Reject;
                }
                break;
            }
            resp.Decision = BFEvaluationDecision::Accept;
            print("Skipped freewheel!", Severity::Success);
            simManager.SetSimulationTimeLimit(0.0);
            break;
        }

        if (optimizeTime) {
            //tracking time
            time = raceTime;
        } else {
            //tracking position during search
            if (currDirection == direction[0] or currDirection == direction[2]) {
                currPos = posX;
            } else if (currDirection == direction[1] or currDirection == direction[3]) {
                currPos = posZ;
            }
        }

        break;
    default:
        break;
    }

    return resp;
}

void printBase()
{

    string message;

    if (optimizeTime) {
        message = "Base time not freewheeled: " + Time::Format(time) + "s";
    } else {
        message = "Base";
        if (currDirection == direction[0]) {
            message += " X not freewheeled: " + best + " (+X) (RaceTime: " + Time::Format(time) + ")";
        } else if (currDirection == direction[1]) {
            message += " Z not freewheeled: " + best + " (+Z) (RaceTime: " + Time::Format(time) + ")";
        } else if (currDirection == direction[2]) {
            message += " X not freewheeled: " + best + " (-X) (RaceTime: " + Time::Format(time) + ")";
        } else if (currDirection == direction[3]) {
            message += " Z not freewheeled: " + best + " (-Z) (RaceTime: " + Time::Format(time) + ")";
        }
    }
    
    

    /*if (optimizeSpeed) {
        if (frontrwheel and frWheel or backrwheel and brWheel or frontlwheel and flWheel or backlwheel and blWheel) {
            message += " | Best Speed, Selected Wheels";
        }
        message += " | Best Speed: " + bestSpeed;
    }

    if (minSpeed > 0) {
        if (min_wheels > 0) {
            message += " | Min Speed, Min Wheels";
        } else {
            message += " | Min Speed";
        }
        if (frontrwheel and frWheel or backrwheel and brWheel or frontlwheel and flWheel or backlwheel and blWheel) {
            message += " | Min Speed, Selected Wheels";
        }
    }

    if (frontrwheel and frWheel or backrwheel and brWheel or frontlwheel and flWheel or backlwheel and blWheel) {
        message += " | Selected Wheels";
    }*/

    print(message);

}

bool isBetter(SimulationManager@ simManager)
{

    bool frontrwheel = simManager.Wheels.FrontRight.RTState.HasGroundContact;
    bool backrwheel = simManager.Wheels.BackRight.RTState.HasGroundContact;
    bool frontlwheel = simManager.Wheels.FrontLeft.RTState.HasGroundContact;
    bool backlwheel = simManager.Wheels.BackLeft.RTState.HasGroundContact;

    int count = 0;
    if (frontlwheel) count++;
    if (frontrwheel) count++;
    if (backrwheel) count++;
    if (backlwheel) count++;

    bool better = false;

    //accept time improvements
    if (optimizeTime) {
        if (time > bestTime) {
            if (minSpeed > 0) {
                if (velocity >= minSpeed) {
                    print(MakeImprovementMessage(simManager), Severity::Success);
                    better = true;
                }
            } else if (optimizeSpeed and velocity >= bestSpeed) {
               print(MakeImprovementMessage(simManager), Severity::Success);
                bestSpeed = velocity;
                better = true;
            // if min speed is not used, still accept
            } else {
                print(MakeImprovementMessage(simManager), Severity::Success);
                better = true;
            }

            if (min_wheels > 0 and count >= min_wheels) {
                print(MakeImprovementMessage(simManager), Severity::Success);
                better = true;
            } else if (frontrwheel and frWheel or backrwheel and brWheel or frontlwheel and flWheel or backlwheel and blWheel) {
                print(MakeImprovementMessage(simManager), Severity::Success);
                better = true;
            }
        }
    }
    //accept position improvements
    else {
        if (currDirection == direction[0] or currDirection == direction[1]) {
            if (optimizeSpeed) {
                better = currPos >= best and velocity > bestSpeed;
            } else {
                better = currPos > best;
            }

            if (minSpeed > 0) {
                better = velocity >= minSpeed and currPos > best;
            }

            if (min_wheels > 0 and count >= min_wheels) {
                better = currPos > best;
            } else if (frontrwheel and frWheel or backrwheel and brWheel or frontlwheel and flWheel or backlwheel and blWheel) {
                better = currPos > best;
            }
        } else if (currDirection == direction[2] or currDirection == direction[3]) {
            if (optimizeSpeed) {
                better = currPos <= best and velocity > bestSpeed;
            } else {
                better = currPos < best;
            }

            if (minSpeed > 0) {
                better = velocity >= minSpeed and currPos < best;
            }

            if (min_wheels > 0 and count >= min_wheels) {
                better = currPos < best;
            } else if (frontrwheel and frWheel or backrwheel and brWheel or frontlwheel and flWheel or backlwheel and blWheel) {
                better = currPos < best;
            }
        }
    }

    if (better) {
        if (optimizeTime) {
            bestTime = time;
        } else {
            print(MakeImprovementMessage(simManager), Severity::Success);
            if (optimizeSpeed) {
                bestSpeed = velocity;
            }
            best = currPos;
        }
    }

    return better;
}

string MakeImprovementMessage(SimulationManager@ simManager) {
    bool frontrwheel = simManager.Wheels.FrontRight.RTState.HasGroundContact;
    bool backrwheel = simManager.Wheels.BackRight.RTState.HasGroundContact;
    bool frontlwheel = simManager.Wheels.FrontLeft.RTState.HasGroundContact;
    bool backlwheel = simManager.Wheels.BackLeft.RTState.HasGroundContact;

    int count = 0;
    if (frontlwheel) count++;
    if (frontrwheel) count++;
    if (backrwheel) count++;
    if (backlwheel) count++;

    string improvementmessage;

    if (optimizeTime) {
        improvementmessage = "Found more time not freewheeled: " + bestTime;
    } else {
        improvementmessage = "Found better Position not freewheeled: " + Text::FormatFloat(best, "", 0, 10);

        if (currDirection == direction[0]) {
            improvementmessage += " (+X) ";
        } else if (currDirection == direction[1]) {
            improvementmessage += " (+Z) ";
        } else if (currDirection == direction[2]) {
            improvementmessage += " (-X) ";
        } else if (currDirection == direction[3]) {
            improvementmessage += " (-Z) ";
        }

        improvementmessage += "(RaceTime: " + Time::Format(time) + ")";
    }

    /*if (minSpeed > 0) {
        improvementmessage += " | Min Speed, " + velocity;
    }

    //improvementmessage = "Found improvement, ";
    // optimize speed with wheels

    if (optimizeSpeed) {
        if (min_wheels > 0 and count >= min_wheels) {
            improvementmessage += " | Best Speed: " + bestSpeed + ", Min Wheels";
        } else if (frontrwheel and frWheel or backrwheel and brWheel or frontlwheel and flWheel or backlwheel and blWheel) {
            improvementmessage += " | Best Speed: " + bestSpeed + ", with Selected Wheels";
        } else {
            improvementmessage += " | Best Speed: " + bestSpeed;
        }
    } else {
        if (min_wheels > 0 and count >= min_wheels) {
            improvementmessage += " | Min Wheels";
        } else if (min_wheels == 0 and frontrwheel and frWheel or backrwheel and brWheel or frontlwheel and flWheel or backlwheel and blWheel) {
            improvementmessage += " | Selected Wheels";
        }
    }*/

    return improvementmessage;
}

void Main()
{
    RegisterVariable("freewheel_min_time", 0);
    RegisterVariable("freewheel_max_time", 0);
    RegisterVariable("freewheel_min_speed", 0);
    RegisterVariable("freewheel_optimizespeed", false);
    RegisterVariable("freewheel_optimizetime", false);
    RegisterVariable("freewheel_currdirection", direction[0]);
    RegisterVariable("freewheel_min_wheels",0);
    min_time = uint(Math::Max(0, int(GetVariableDouble("freewheel_min_time"))));
    max_time = uint(Math::Max(0, int(GetVariableDouble("freewheel_max_time"))));
    minSpeed = uint(Math::Max(0, float(GetVariableDouble("freewheel_min_speed"))));
    min_wheels = uint(Math::Max(0, int(GetVariableDouble("freewheel_min_wheels"))));
    SetVariable("freewheel_min_wheels", min_wheels);
    SetVariable("freewheel_min_time", min_time);
    SetVariable("freewheel_max_time", max_time);
    SetVariable("freewheel_min_speed", minSpeed);

    optimizeSpeed = GetVariableBool("freewheel_optimizespeed");
    optimizeTime = GetVariableBool("freewheel_optimizetime");
    currDirection = GetVariableString("freewheel_currdirection");

    RegisterBruteforceEvaluation("freewheel", "Free Wheeling", OnEvaluate, RenderEvalSettings);
    log("Plugin started.");
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Free-wheel BF";
    info.Author = "Gl1tch3D";
    info.Version = "v2.2.0";
    info.Description = "Searches for the least amount of freewheel time.";
    return info;
}
