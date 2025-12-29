import("stdfaust.lib");

fs = 48000;

// Custom Lookahead Limiter Block
// Parameters: Threshold (dB), Attack (s), Release (s), Lookahead (s)
customLimiter(th_db, att_s, rel_s, lookahead_samples) = _ <: (delay_path, gain_lin) : *
with {
    // 1. Signal Path Delay
    // Max delay is set to 4096 samples to ensure memory allocation is sufficient.
    // The delay time is converted from seconds to samples.
    // de.sdelay(max_delay, interpolation, current_delay)
    //d_samples = lookahead_s * ma.SR;
    delay_path = de.sdelay(128, 16, lookahead_samples);

    // 2. Sidechain Gain Calculation
    // We analyze the UNDELAYED signal to calculate gain for the future.
    // co.peak_compression_gain_mono_db calculates the required gain reduction in dB.
    // Arguments: Strength (1=Limiter), Threshold, Attack, Release, Knee, Pre/Post
    gain_db = co.peak_compression_gain_mono_db(1, th_db, att_s, rel_s, 0, 0);
    
    // Convert dB gain to linear scale (0.0 - 1.0)
    gain_lin = gain_db : ba.db2linear;

    // 3. Application
    // Split input: one path goes to delay, one to sidechain. 
    // Multiply delayed signal by calculated gain.
};

// --- User Interface Parameters ---
// Crossover Frequencies
XO1 = hslider("Low X-Over [unit:Hz]", 200, 20, 1000, 1);
XO2 = hslider("High X-Over [unit:Hz]", 3000, 1000, 10000, 1);

// Limiter Settings
Thresh = hslider("Threshold", -12, -60, 0, 0.1);
Attack = hslider("Attack [unit:s]", 0.001, 0.0001, 0.1, 0.0001);
Release = hslider("Release [unit:s]", 0.1, 0.01, 1.0, 0.01);
Lookahead = hslider("Lookahead [unit:samples]", 128, 8, 4096, 8);

// 3-way Crossover: Splits 1 signal into 3
// Syntax: _ : fi.crossover3LR4(freq1, freq2) : _,_,_
// myCrossover = fi.crossover3LR4(XO1, XO2);
myCrossover = fi.crossover2LR4(XO1);

// Processing Chain for One Channel
process_mono = myCrossover : (
    customLimiter(Thresh, Attack, Release, Lookahead), // Low Band
 //   customLimiter(Thresh, Attack, Release, Lookahead), // Mid Band
    customLimiter(Thresh, Attack, Release, Lookahead)  // High Band
) :> _; // Sum the 3 bands back to 1 signal

// process_mono = customLimiter(Thresh, Attack, Release, Lookahead);
// process_mono = _;


// pico dsp left(L) microphone is the one closest to the TRS connectors, right(R) microphone is the one closest to the RF antenna  //

L = _ : fi.dcblocker : process_mono;  // adjust for mic input dc offset, which is ~ 0.7v
R = _ : fi.dcblocker : process_mono;

// omnidirectional //
process = L, R;   // comment out this line for both mics in omnidirectional configuration 

// Main Process: Stereo Duplication
// We apply the mono process to both Left and Right input channels in parallel.
// process = _,_ : par(i, 2, process_mono);

