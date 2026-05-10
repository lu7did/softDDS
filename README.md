# softDDS

Soft DDS using a rp2040 processor

The outputs at GPIO13 and GPIO14 would be a clock at the operating frequency.

#### Architecture

The architecture combines:

* Dynamic reconfiguration of the board clock (PLL_SYS).
* Generate quadrature signals using a 4-state PIO logic.
* Manipulate the fractional divisor (Q8.8) of the PIO state machine.
* Perform a frequency optimization of the error.

The system achieves typical errors in the 0-50 Hz range over the HF spectrum, being the receiver clock 
and being stable on that error this is quite compatible with digital modes such as FT8, the only effect
would be than the *"nominal"* frequency of the incoming signal with be shifted up or down by the error
(few Hz) in a stable way.


Main components are

* PLL_SYS (RP2040).
* Main boar clock (clk_sys).
* Configurable divider:
	* refdiv
	* fbdiv
	* postdiv1
	* postdiv2
* PIO (Programmable I/O)

The PIO executes a cyclic firmware with 4 states which generates the quadrature
signal over 2 output pins

	00 → 01 → 11 → 10 → repeat

Each instruction is executed in one clock cycle of the state machine, therefore
manipulating the clock of that PIO state machine using a fractional divider the
output frequency can be manipulated:

$D=d_{int}+\frac{d_{frac}}{256}$

Selecting two consecutive pins the signals *I* and *Q* can be extracted from each.

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

The resulting waveform is similar to the following example (for 3.5 MHz)
![Alt Text](doc/ADX-ddsPIO_quad.png?raw=true "ADX-ddsPIO Quadrature frequency synthetizer")  

