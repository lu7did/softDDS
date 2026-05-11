# softDDS

Soft DDS using a rp2040 processor

The outputs at GPIO13 and GPIO14 would be the clock output at the operating frequency.

## Clock operation description

The rp2040 processor has several specialized processors
called *PIO* (**Programmable Input/Output**) which are a limited memory, limited instruction set (RISC)
processors but completely independent from the main processor. Each processor executes their 
program as part of a *state machine* (SM) which dictates which instruction is executed
at each clock cycle.  They are programmed in a special 
Assembler language (*PioASM*) and are extremely useful to perform I/O without tying up the
processor or forcing the handling of interrupts on the main cores.  

To generate a clock for the intermediate frquency a PIO is assigned with that purpose
the state machine (SM) of the selected PIO runs at the frequency $f_{sm}$.
If the PIO program makes a toggle of the signal every cycle then the output frequency ($f_{out}$) would be:

$f_{out}=\frac{f_{sm}}{2}$

If, as an example, the clock has an estimated 465 KHz frequency (i.e. to operate as the BFO of a IF at a receiver) then

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

This level of error might be a good compromise between performance, cost and simplicity at a lower
frequency. However,  it might become too coarse for a higher frequency signal generator.

## Frequency error correction algorithm

The architecture combines:

* Dynamic reconfiguration of the board clock (PLL_SYS).
* Generate quadrature signals using a 4-state PIO logic.
* Manipulate the fractional divisor (Q8.8) of the PIO state machine.
* Perform a frequency optimization of the error.

Using it the system achieves typical errors in the 0-50 Hz range over the HF spectrum, being the receiver clock 
and being stable on that error this is quite compatible with digital modes.


Main components are

* PLL_SYS (RP2040).
* Main board clock (clk_sys).
* Configurable divider:
	* refdiv
	* fbdiv
	* postdiv1
	* postdiv2
* PIO (Programmable I/O)

The PIO executes a cyclic firmware with 4 states which generates the required
signal over 2 output pins

	00 → 01 →  → 11 → repeat

Each instruction is executed in one clock cycle of the state machine, therefore
manipulating the clock of that PIO state machine using a fractional divider the
output frequency can be manipulated:

$D=d_{int}+\frac{d_{frac}}{256}$

The two selected consecutive pins will be independent outputs of the oscilator.

The synthesis math model follows

Each instruction of the PIO is executed in:
$T_{inst}=\frac{D}{f_{clk_sys}}$ 

In order to complete a full period all 4 instructions needs to be executed

$T_{out} = 4 \times T_{inst}  = \frac{4D}{f_{clk_sys}}$ 

Therefore the output frequency ($f_{out}$) will be:
$f_{out}=\frac{f_{clk_sys}}{4D}$

Using
$N=256D$

Results

$f_{out}=\frac{f_{clk_sys} \times 64}{N}$

Which is the master equation of the system operation

When a target frequency ($f_{req}$) is needed as a goal
and the system is running with a clock ($f_{clk}$) the
problem is to define a divider


$N^*=\frac {f_{clk} \times 64}{f_{req}}$ 

But the hardware is limited to 
$N \in Z,1 \le 65535$

Therefore not all values of $N$ are feasible but
$N=Round({N^*})$

And the true frequency resulting would be

$f_{out} (N)=\frac{f_clk \times 64}{N}$

and the error 
$ε=f_{out} (N)-f_{req}$

When computed over the HF range the error could become quite large, from
several Hz in the lower bands to close to 30 KHz in the higher bands, this
is not acceptable.

To minimize the error two factors needs to be defined, the divisor but also the system clock
in a way that an exploration of the  discrete space of solutions 

* $refdiv\in[1,16]$
* $fbdiv\in[16,320]$
* $postdiv1\in[1,7]$
* $postdiv2\in[1,postdiv]$

With:
* $f_{ref}=\frac{f_{xosc}}{refdiv}$
* $f_{vco}=\frac{f_ref}{fbdiv}$
* $f_{clk}=\frac{f_{vco}}{postdiv1 \times postdiv2}$

Subject to the following constraints:

* $400 \text{MHz} \le f_{vco} \le 1600 \text{MHz}$
* $f_{clk} \le f_{max_sys}$

 
A minimization optimization problem can then be solved with the 
following border conditions

For each valid PLL configuration a computation is made
$N^*=\frac {f_{clk} \times 64}{f_{req}}$ 

All candidates are evaluated
$[N-1,N,N+1]$

For each 
$f_{out} (N)=\frac {f_{clk} \times 64}{N}$

Searching for the minimum of 
$\left \lvert \epsilon \right \rvert = \left \lvert {f_{out}-f_{req}} \right \rvert$

Selecting as a result the value with the minimum absolute 
error 
$[f_{clk},N]$

This is a discrete search with a double optimization:
* PLL quantization.
* Divider (Q8.8) quantization

The theoretical error limit is  
$\left \lvert \Delta N \right \rvert \le 0.5$

taking derivatives 
$\frac {df}{dN}=- \frac{f_{clk} \times 64}{N^2}$

Being the approximate máximum error value:
$\left \lvert \epsilon_{max} \right \rvert \approx \frac{f_{clk} \times 64}{2 \times N^2}$

Since
$N \approx \frac{f_{clk} \times 64}{f_{req}}$ 

results
$\left \lvert {\epsilon}_{max} \right \rvert \approx \frac{f_{req}^2}{2 \times f_{clk} \times 64}$

As a consequence 

* Error is reduced when $clk_{sys}$ increases.
* Error grow quadratically with the $f_{req}$
* The divisor cuantization controls the residual error.

A typical expected result would be
|Band|Freq|clk_sys|Error|
| --- | --- | --- | --- |
| 80 m |  3 573 000 | 167 428 571 |   0 Hz |
| 40 m |  7 074 000 | 233 000 000 |  ±3 Hz |
| 20 m | 14 074 000 | 268 285 602 |  ±2 Hz |
| 15 m | 21 074 000 | 178 800 000 | ±30 Hz |
| 10 m | 28 074 000 | 261 000 000 | ±50 Hz |


The output of this clock is implemented to be obtained at pins GPIO14 (I) and GPIO15 (Q).


