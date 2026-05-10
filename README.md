# softDDS

Soft DDS using a rp2040 processor

### Dual clock 

In this setup the clock is produced simultaneously from GPIO13 and GPIO14, both signals
are identical. This configuration is intended to make the circuit
simpler. Actual operation of the board will require other signals such as RXSW and TXA
to properly operate to be controlled by the firmware.


### Dual clock

Then the board operates with a superheterodyne receptor configuration the receiver process
requires two clocks, the main one to operate the down-converter mixer from the HF frequency
to an intermediate frequency and other as the intermediate frequency oscillator frequency.

The down-converter local oscillator (RFLO) can be either one of the clocks despicted above.

The intermediate frequency clock (RFIF) is a special clock, it's lower in frequency and 
therefore it's easier to implement on a processor with limited resources. Also it's a 
fixed frequency as it doesn't vary with the operation.

The rp2040 processor has several specialized processors
called PIO (Programmable Input/Output) which are a limited memory, limited instruction set (RISC)
processors but completely independent from the main processor. Each processor executes their 
program as part of a *state machine* (SM) which dictates which instruction is executed
at each clock cycle.  They are programmed in a special 
Assembler language (*PioASM*) and are extremely useful to perform I/O without tying up the
processor or forcing the handling of interrupts on the main cores.  

To generate a clock for the intermediate frquency a PIO is assigned with that purpose
the state machine (SM) of the selected PIO runs at the frequency $f_{sm}$.
If the PIO program makes a toggle of the signal every cycle then the output frequency ($f_{out}$) would be:

$f_{out}=\frac{f_{sm}}{2}$

For an estimated 465 KHz frequency for the IF of the receiver then

$f_{sm}= 2*465 KHz = 930 KHz$

The clock used by the PIO is derived from the system clock ($clk_{sys}$) thru a fractional divisor,
as the board is being clocked at 270 MHz then

$clk_{div} = \frac{clk_{sys}}{f_{sm}} = 270e6 / 930e3 \approx{290.32266}$

However, the actual divisor used by the rp2040 has a resolution of 1/256, so in this case:


$f_{out} = \frac{f_{clk}}{2 \cdot div}$


where:


$div = INT + \frac{FRAC}{256}$

The ideal divisor would be 

$div_{ideal} = \frac{f_{clk}}{2 \cdot f_{obj}}$

$div_{ideal} = \frac{270\,000\,000}{2 \cdot 465\,000} = 290.3236$

As the hardware allows only for steps of 

$\Delta div = \frac{1}{256} \approx 0.00390625$

A split is made:

$INT = 290$

$FRAC = round(0.3236 \cdot 256) = 82$

A split needs to be made

$div_{real} = 290 + \frac{82}{256} = 290.3203$

And the real frequency obtained would be

$f_{real} = \frac{270\,000\,000}{2 \cdot 290.3203}$

$f_{real} \approx 465003.6529 \ \text{Hz}$

The quantization introduces then an error of 

$\Delta f = f_{real} - f_{obj}$

$\Delta f \approx -3.6529 \ \text{Hz}$

Being the relative error 

$\varepsilon = \frac{\Delta f}{f_{obj}}$
$\approx 7.85 \times 10^{-6}$

$\varepsilon \approx 8 \ \text{ppm}$

This error factor is accounting **only** for the fractional divisor error of the PIO. Other sources
of error needs to be considered such as
* Board crystal tolerances.
* PLL error.
* Thermal drift.
* Fractional divider internal jitter.

However, the level of error obtained is a good compromise between performance, cost and simplicity.

The waveform obtained at GPIO15 is as follows for a nominal $f_{BFO}=446400 \text{Hz}$

![Alt Text](doc/ADX-ddsPIO_BFO.png?raw=true "ADX-ddsPIO BFO")  

The outputs at GPIO13 and GPIO14 would be a clock at the operating frequency whilst the output
at GPIO15 (when option **#define SUPERHET 1** is set) would be a fixed clock of the established
frequency (normally in the 450 KHz range) as shown in the following picture.

