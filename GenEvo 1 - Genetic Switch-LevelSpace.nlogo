breed [LacIs LacI]       ;; LacI repressior protein (violet proteins)
breed [LacZs LacZ]       ;; LacZ beta-galactosidase emzyme (red proteins)
breed [ LacYs LacY ]     ;; LacY lactose permease enzyme (orange proteins)
breed [ RNAPs RNAP ]     ;; RNA Polymerase (brown proteins) that binds to promoter part of DNA and synthesizes mRNA from the downstream DNA
breed [lactoses lactose] ;; Lactose molecules (yellow)

LacIs-own [
  partner      ;; parter is a lactose molecule with which LacI forms a complex
  inhibitor?   ;; a boolean to track if a LacI is bound to DNA as an inhibitor of transciption
]

RNAPs-own [on-dna?] ;; a boolean to track if a RNAP is trascribing on DNA

lactoses-own [
  partner     ;; a partner is a lacI molecule with which an ONPG forms a complex
  inside?     ;; a boolean to track if a lactose molecule is inside the cell
]

globals
[ view-width       ;; global veriables to manage view and cell-dimensions (these are only for display purpose)
  view-height
  cell-width
  cell-height

  operon-transcribed?            ;; a boolean to track a transciption event
  LacZ-production-num
  LacZ-production-cost
  LacY-production-num
  LacY-production-cost
  energy-value ;; keeps track of the energy value of the cell
  ini-energy-value
  ini-lactose-num
  outside-lactose
  lactose-catabolism-chance
  lacy-patch-counts
  laci-lactose-complex-count
  division-number
  inhibited?         ;; boolean for whether or not the operator is inhibited

  ;; patch agentsets
  cell-wall         ;; agentset containing the patches that are cell wall
  cell-patches      ;; agentset containing the patches that are inside the cell wall
  dna               ;; agentset containing the patches that are DNA
  operon            ;; agentset containing the patches that are the Lac-operon
  promoter          ;; agentset containing the patches that are for the promoter
  operator          ;; agentset containing the patches that are for the operator
  terminator        ;; agentset containing the patches that are for the terminator
  var-list
  var-name-list
  cell-division-time
  cell-color
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; Setup Procedures ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ;; First we ask the patches to draw themselves and set up a few variables
  if ( not Level-Space? ) [
    ca
    set cell-color brown
  ]
  set-global-variables
  set-patches
  add-proteins
  make-var-name-list
  create-var-list
  reset-ticks
end

to set-global-variables
  set LacY-production-num 5
  set LacY-production-cost 10
  set LacZ-production-num 5
  set LacZ-production-cost 10
  set ini-lactose-num 2500
  set operon-transcribed? false
  set view-height 32
  set view-width 64
  set cell-width (view-width - 20)
  set cell-height (view-height - 16)
  set inhibited? false
  set energy-value 3000
  set ini-energy-value energy-value
  set lacy-patch-counts [ ]
  set laci-lactose-complex-count 0
  set lactose-catabolism-chance base-lactose-catabolism-chance
  set division-number 0
end

to add-proteins
  create-lacIs lacI-number [                  ;; starts with constant number of LacIs
    set inhibitor? false
    set partner nobody
    setshape
    genXY-inside
  ]
  create-RNAPs RNAP-number [                 ;; starts with constant number of RNAPs
    set on-dna? false
    setshape
    genXY-inside
  ]
end

to set-patches  ;; sets patches for the cell, the cell-wall, different regions of the DNA

  ask patches [ set pcolor black ]   ;; the background is set black.

  ;; cell-wall set as 'cell-color'
  set cell-wall patches with
  [((pycor = cell-height or pycor = (- cell-height)) and (pxcor > (-(cell-width + 1)) and pxcor < (cell-width + 1))) or
    ((pxcor = cell-width or pxcor = (- cell-width)) and (pycor > (-(cell-height + 1)) and pycor < (cell-height + 1)))]
  ask cell-wall [ set pcolor cell-color ]

  ;; patches inside the cell-wall are set white.
  set cell-patches patches with
  [(((pycor < cell-height and pycor > (- cell-height))) and (pxcor > (- cell-width) and pxcor < (cell-width)))]
  ask cell-patches [ set pcolor white ]

  ;; specifies the DNA region inside the cell
  set dna patches with [
    (pycor > -1) and (pycor < 2) and (pxcor > -22 and pxcor < 18)
  ]

  ;; the operon patches are blue
  set operon patches with [
    (pycor > -1 and pycor < 2) and (pxcor > -10 and pxcor < 17)
  ]
  ask operon [ set pcolor blue ]

  ;; promoter is green
  set promoter patches with [
    (pycor > -1 and pycor < 2) and (pxcor > -22 and pxcor < -14)
  ]
  ask promoter [ set pcolor green ]

  ;; operator is orange
   set operator patches with [
     ((pycor = 0) and (pxcor > -15 and pxcor < -9)) or
     (( pycor = 1) and (( pxcor = -10) or ( pxcor = -12) or ( pxcor = -14)))
   ]
  ask operator [ set pcolor orange ]

  ;; the terminator patches are gray
  set terminator patches with [
    ((pycor > -1) and (pycor < 2)) and ((pxcor > 16 and pxcor < 19))
  ]
  ask terminator [ set pcolor gray ]

end

;; procedure that assigns a specific shape to a turtle, and shows
;; or hides it, depending on its state
to setshape
  if breed = LacIs
  [ set size 6
    ifelse partner = nobody
    [ set shape "laci"]
    [ set shape "laci-lactose-complex" set size 6 set laci-lactose-complex-count laci-lactose-complex-count + 1]
  ]
  if breed = RNAPs
    [ set size 5
      set shape "RNAPol"
      set color brown]
  if breed = lactoses
    [
      ifelse partner = nobody
      [
        set shape "pentagon"
        set hidden? false
        set size 2
      ]
      [
        set hidden? true
      ]
    ]
  if breed = LacYs
    [ set shape "pump"
      set color red
      set size 3]

  if breed = LacZs
    [ set shape "protein"
      set color red
      set size 3]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; go procedures ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  update-energy
  check-transcription
  go-LacIs
  go-LacYs
  go-LacZs
  go-lactoses
  go-RNAPs
  degrade-proteins
  dissociate-complex
  create-var-list
  if ( not Level-Space?) [
    divide-cell
    update-lactose
    if (energy-value < 0) [
      user-message ["The cell has run out of energy. It's dead!"]
      stop
    ]
  ]
  calculate-cell-division-time
  tick
end

to update-energy
  set energy-value (energy-value - floor ( count RNAPs + count LacIs + count lacZs) / 10 )
end

to check-transcription
  if (operon-transcribed?) [
    create-proteins
    set operon-transcribed? false
  ]
end

;;;;;; LacI procedures ;;;;;;;

to go-LacIs
  ask lacIs [
    ifelse inhibitor? [
       if (random-float 1 < lacI-bond-leakage) [ dissociate-from-operator ]
    ]
    [
      move
      if (inhibited? = false) and ((member? patch-here operator) or (member? patch-ahead 1 operator)) and (partner = nobody) [ bind-to-operator ]
      if partner = nobody [bind-to-lactose]
    ]
  ]
end

to bind-to-operator
    set inhibitor? true
    set inhibited? true
    set heading 0
    setxy -12 1
end

to dissociate-from-operator
      set inhibitor? false
      set inhibited? false
      fd 3
end

to bind-to-lactose
    set partner one-of (other lactoses-here with [partner = nobody])
    if partner = nobody [ stop ]
    if [partner] of partner != nobody [ set partner nobody stop ]  ;; just in case two lacIs grab the same partner
    ifelse ((([breed] of partner) = lactoses) and ((random-float 100) < complex-formation-chance))
      [ ask partner [ set partner myself ]
        setshape
        ask partner [ setshape ]
        if (inhibitor?) [
          set inhibited? false
          set inhibitor? false
          fd 1
        ]
      ]
      [set partner nobody]
end

;;;;;;;; LacY procedures ;;;;;;;;

to go-LacYs
  ask lacYs [
    ifelse(([pcolor] of patch-ahead 1) = cell-color) [       ;; if lacY hits the cellwall, it gets installed on the cellwall
      install-on-cellwall
    ]
    [
      while [[pcolor] of patch-ahead 1 = red] [      ;; if there is already a lacY on the cellwall, it moves in a random direction
        rt random-float 360
      ]
    ]
    move
  ]
end

to install-on-cellwall
  ask patch-ahead 1 [set pcolor red]
  die
end

;;;;;;;; LacZ procedures ;;;;;

to go-lacZs
  ask lacZs [
    move
    if count Lactoses-here != 0 [
      digest-lactose
    ]
  ]
end

to digest-lactose
  ask one-of Lactoses-here [ die ]
  set energy-value energy-value + 20
end

;;;;;;;; lactose procedures ;;;;;

to go-lactoses
  ask lactoses [
    ifelse ([pcolor] of patch-ahead 1 = red and not inside?) [
      fd 3
      set inside? true
    ]
    [
      while [[pcolor] of patch-ahead 1 = red or [pcolor] of patch-ahead 1 = cell-color] [
        rt random-float 360
      ]
      fd 1
    ]
    rt random-float 360
  ]
end

;;;;;;; RNAP procedures ;;;;;

to go-RNAPs

  ;; If a RNAP is close or on the promoter (green) and the operator is open, change heading and move on the DNA towards the terminator.
  if (not inhibited?) [
    ask RNAPs [
      if (member? patch-here promoter) or (member? patch-ahead 1 promoter) [
       bind-to-promoter
      ]
    ]
  ]

  if any? RNAPS with [on-dna?] [
    ask RNAPs with [on-dna?] [
      transcribe-operon
    ]
  ]

  ask RNAPs with [not on-dna?] [
    move
  ]
end

to bind-to-promoter
  setxy xcor 1
  set heading 90
  set on-dna? true
end

to transcribe-operon
  fd 1
  if (member? patch-here terminator) [
    set operon-transcribed? true
    set on-dna? false
    genXY-inside
  ]
end

;;;;;;; sysntehsis procedures ;;;;;;

to create-proteins
    create-LacYs LacY-production-num [
      genXY-inside
      setshape
    ]
    create-LacZs LacZ-production-num [
      genXY-inside
      setshape
    ]

    ;; Energy calculations - synthesis of one LacY or LacZ reduces energy by 10 units
    set energy-value energy-value - ((LacY-production-cost * LacY-production-num) + (LacZ-production-cost * LacZ-production-num))
end


to degrade-proteins
  ;; degrade lacYs on the cellwall
  ask patches with [pcolor = orange] [
    if random-float 1 < lacY-degradation-chance [
      set pcolor cell-color
    ]
  ]
  ;; degrade LacZs
  ask LacZs [
    if random-float 1 < LacZ-degradation-chance [
      die
    ]
  ]
end

to dissociate-complex
  ask lacIs with [partner != nobody] [
    if random-float 1 < complex-separation-chance [
      let temp-x xcor
      let temp-y xcor
      ask partner [
        set partner nobody
        setxy temp-x temp-y
        setshape
        fd 1
      ]
      set partner nobody
      setshape
      set laci-lactose-complex-count laci-lactose-complex-count - 1
      fd -1
    ]
  ]
end

to move
  if (breed != LacYs) and (xcor > (cell-width - 3) or xcor < (- cell-width + 3)) [
    genXY-inside
  ]
  while [([pcolor] of patch-ahead 1 = red or [pcolor] of patch-ahead 2 = red or [pcolor] of patch-ahead 1 = cell-color or [pcolor] of patch-ahead 2 = cell-color)] [
    rt random-float 360
  ]
  fd 1
  rt random-float 360
end

;; adds lactose in the outside environment of the cell
to add-lactose [num-lactose]
  create-lactoses num-lactose [
    genXY-outside
    set inside? false
    set partner nobody
    setshape
  ]
end

to genXY-inside
  setxy random-xcor random-ycor
  while [(not (((xcor < (cell-width - 1)) and (xcor > (- (cell-width - 1)))) and ((ycor < (cell-height - 1)) and (ycor > (- (cell-height - 1))))))] [
    setxy random-xcor random-ycor
  ]
end

to genXY-outside setxy random-xcor random-ycor
  while [(not (((xcor > (cell-width + 1)) or (xcor < (- (cell-width + 1)))) or ((ycor > (cell-height + 1)) or (ycor < (- (cell-height + 1))))))] [
    setxy random-xcor random-ycor
  ]
end

to divide-cell
  if energy-value > 2 * ini-energy-value [
    let half-lacy-count ( count patches with [pcolor = red] ) / 2
    ask n-of half-lacy-count patches with [pcolor = red] [set pcolor cell-color]
    set energy-value energy-value / 2
    let half-lactose-inside ( count lactoses with [inside?] ) / 2
    ask n-of half-lactose-inside lactoses [die]
    let half-lacY-inside-count count lacYs / 2
    ask n-of half-lacY-inside-count lacYs [die]
    set lactose-catabolism-chance ( base-lactose-catabolism-chance + ( lactose-catabolism-chance - base-lactose-catabolism-chance ) / 2 )
    set division-number division-number + 1
    set laci-lactose-complex-count count lacis with [partner != nobody]
  ]
end

to make-var-name-list
  set var-name-list ["energy-value" "LacYs" "lacY-installed" "lacI-lacotose-complex" "lactose-inside" "lactose-outside"]
end

to create-var-list
  set var-list (list (energy-value) (count LacYs) (count (patches with [pcolor = orange])) (count (lacIs with [partner != nobody])) (count (lactoses with [inside?])) (count (lactoses with [not inside?])))
end

to update-lactose
  if ( constant-lactose? ) [
    add-lactose ( outside-lactose - count lactoses with [ inside? = false] )
  ]
end

;to update-lactose [numb-lactose]
;  let lactose-outside count lactoses with [not inside?]
;  ifelse (lactose-outside >= numb-lactose) [
;    ask n-of (lactose-outside - numb-lactose) lactoses with [not inside?] [die]
;  ]
;  [
;    add-lactose ( numb-lactose - lactose-outside )
;  ]
;end

to calculate-cell-division-time
  if division-number > 0 [
    set cell-division-time ticks / division-number
  ]
end

to set-cell-color [my-cell-color]
  set cell-color my-cell-color
end


; Copyright 2003 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
605
10
1151
337
60
33
4.43
1
12
1
1
1
0
1
1
1
-60
60
-33
33
1
1
1
ticks
30.0

BUTTON
10
10
65
43
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
70
10
125
43
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
20
355
200
388
LacI-bond-leakage
LacI-bond-leakage
0
0.01
0.002
0.001
1
NIL
HORIZONTAL

SLIDER
210
395
390
428
Complex-formation-chance
Complex-formation-chance
90
100
98.8
0.1
1
NIL
HORIZONTAL

SLIDER
400
355
580
388
LacY-degradation-chance
LacY-degradation-chance
0
0.01
1.0E-4
0.0001
1
NIL
HORIZONTAL

SLIDER
20
395
200
428
Base-Lactose-catabolism-chance
Base-Lactose-catabolism-chance
0.1
1
0.4
.1
1
NIL
HORIZONTAL

PLOT
10
95
590
345
Energy
NIL
NIL
0.0
10.0
0.0
1000.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot energy-value"

BUTTON
130
10
210
43
Add Lactose
Add-Lactose ini-lactose-num\nset outside-lactose ini-lactose-num\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
440
10
590
43
LacI-number
LacI-number
1
50
16
1
1
NIL
HORIZONTAL

SLIDER
440
55
590
88
RNAP-number
RNAP-number
0
50
16
1
1
NIL
HORIZONTAL

SLIDER
210
355
390
388
Complex-separation-chance
Complex-separation-chance
0
1
0.03
0.01
1
NIL
HORIZONTAL

PLOT
295
440
590
600
LacY count
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot ( count patches with [pcolor = orange] + count lacYs )"

PLOT
10
440
280
600
% Complex Formed
NIL
NIL
0.0
10000.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot ((laci-lactose-complex-count / count lacis) * 100 )"

PLOT
605
440
910
600
Lactose Catabolism Chance
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot lactose-catabolism-chance"

SLIDER
400
395
580
428
LacZ-degradation-chance
LacZ-degradation-chance
0
0.01
0.0045
0.0001
1
NIL
HORIZONTAL

SWITCH
220
10
435
43
Constant-lactose?
Constant-lactose?
0
1
-1000

PLOT
930
440
1220
600
Growth Rate (average cell division time)
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot cell-division-time"

SWITCH
315
55
435
88
Level-Space?
Level-Space?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model simulates a complex phenomenon in molecular biology: the “switching” (on and off) of genes. Through specific regulatory proteins and specific DNA sequences, each regulated gene has the ability to turn on or off in response to environmental stimuli.

Specifically, we model the “Lac-Operon” of E. coli., which is responsible for the uptake and digestion of lactose through the synthesis of the enzymes permease (LacY) and beta-galactosidase (LacZ). In this model, we explicitly model LacY which inserted on the cellwall to increase uptake of lactose and implicitly model LacZ which increases the rate of catabolism of lactose.


## HOW IT WORKS

This genetic switch is in essence, a positive feedback loop. When there is no lactose in the surrounding environment, the genetic switch in a bacterial cell is at a off steady-state. That is because the repressor protein LacI prevents the bacteria from producing enzymes, by binding to the operator site of the DNA. In this steady state, relatively little permease (LacY) is produced. This is because LacI binding to DNA is 'leaky'. There is some chance that a bound LacI molecule releases from DNA and some permease (LacY) molecules are produced.

When lactose is introduced into the outside environment, the lactose molecules enter into the bacterium through permeases (LacYs) that have latched onto the cellwall. Some lactose molecules that enter the cell bond to LacIs, preventing them from binding to the DNA. This, in turn, causes the RNAPs to produce more LacYs which causes more lactose to enter the cell, thus creating a positive feedback loop. Other lactose is catabolized, producing energy.

There are four important DNA regions in this model -
Promoter – This is indicated with green color. As an RNAP binds to promoter region and if the operator is free, it moves along DNA and separates from DNA at the terminator region.
Operator – This is indicated with red color. The LacI repressor protein binds to this region and when it is bound, RNAP cannot move along the DNA.
Gene – This is indicated with yellow color. This model explicitly shows LacY and implicitly models LacZ. As RNAP moves along the gene, two things happen in this model:
a. LacY molecules are produced (three molecules per RNAP). We do not show –translation by ribosomes in this model.
b. Lactose-catabolism chance (which determines the rate at which lactose is digested) increases. This implicitly models synthesis of LacZ.
Terminator – This is indicated with white color. As an RNAP reaches this part of DNA, it separates from DNA.

There are four important proteins–
RNAP – These are RNA polymerases, that synthesize mRNA from DNA. This model does not include mRNAs. These are blue blobs in the model.
LacI – The purple-colored shapes in the model represent the repressor, LacI proteins. They bind to the operator part of DNA and do not let RNAP to pass along the gene, thus stopping protein synthesis. When lactose binds to LacI, they form LacI-lactose complex (shown by a purple shape with yellow dot attached to it). The complex cannot bind to the operator region of the DNA.
LacY – These are shown in the model with orange rectangles. They are produced when an RNAP passes along the gene. When they hit the cell-wall, they get installed on the cell wall (shown by orange patches). Lactose (yellow pentagons) from outside environment is transported inside the cell through these orange patches.
LacZ – This protein is modelled indirectly by increasing lactose catabolism chance as an RNAP passes along the DNA.

Energy of the cell –
There is a cost of producing and maintaining protein machinery for a cell in terms of energy. So as a cell produces proteins and maintains those (RNAPs and LacIs), it’s energy decreases.
Energy of the cell increases when it digests/catabolizes lactose that is inside.
Cell division -
When the energy of the cells doubles, it divides and it’s energy becomes half. Production and degradation of LacY, LacZ and formation of LacI-lactose complex is modelled here, so a daughter cell received half the quantity of each.

## HOW TO USE IT

Each slider controls a certain aspect of this genetic regulation circuit. Refer to the #Sliders Section for more information on the function of each variable. Once all the sliders are set to the desired levels, the user should click “Setup” to initialize the proteins in the bacterium and “Go” to start the simulation. At any point during the simulation, the user can add lactose to the outside environment by clicking the Add Lactose button. As lactose in transported inside the cell through LacY, it is digested and energy value of the cell increases. The energy units are set arbitrarily. If the energy value set initially doubles, a bacterium divides. In such case, the model shows only one of the daughter cells with half of operon proteins and energy.

### Buttons

SETUP - Sets up the following components of the model:
Cell-wall: A rectangle of brown colored patches that set the boundary of the bacterial cell
DNA: Colored patches inside the cell (Green - promoter, Red - operator, Yellow - LacY gene, White - terminator)
LacI molecules - Red colored turtles inside the cell
RNAP molecules - Blue colored turtles inside the cell

GO - runs the simulation until the cell dies
ADD LACTOSE - Adds 2000 molecules of lactose (yellow pentagons) outside the cell

### Sliders

RNAP-NUMBER - Sets the number of RNAPs
LACI-NUMBER - Sets the number of LacIs
LACI-BOND-LEAKAGE - Sets the chance of detaching a LacI molecule that is bonded to the operator region of the DNA
LACTOSE-CATABOLISM-CHANCE - Sets the chance of catabolism of lactose inside the cell. Once catabolized cell energy is increased.
LACY-DEGRADATION-CHANCE - Sets the chance of degradation of LacY that is installed on the cell-wall
COMPLEX-FORMATION-CHANCE - Sets the chance of formation of a complex of lactose and LacI, when lactose and LacI are near each other
COMPLEX-SEPARATION-CHANCE - Sets the chance of separation of a complex of lactose and LacI

### Plots

ENERGY - Plots the amount of energy in the cell over time
% COMPLEX FORMED – Plots the percentage of LacI molecules are bound to lactose to form LacI-lactose complex
LacY count – Plots the number of lacYs (permeases) inside a cell
Lactose-catabolism-rate – Plot the rate at which the lactose molecules inside the cell are digested. This implicitly indicates number of LacZ molecules.
Growth rate (Average cell division time) -

### Switches

DIE – If ON, the cell dies when it’s energy is zero.
Constant-lactose – If ON the lactose outside the cell is constant, which models an environment with abundant supply of lactose (not uncommon in nature for short amount of time).
Level-Space – This should be OFF, unless the model is to be used as a child model in the level space.

## THINGS TO NOTICE

Notice the molecular mechanism of genetic switch -
Uptake of lactose from outside to inside through LacY
Repression of LacI and formation of lacI-lactose complex to inhibit the repression
Notice the changes in energy of the cells when lactose is added (in case of constant-lactose is ON and OFF).
Notice the energy changes when a cell divides after it’s energy doubles
Changes in the proteins – LacY and LacZ (lactose-catabolism-chance)
Notice the change in the rate of cell division (when constant-lactose is ON)
## THINGS TO TRY

Try to make the cell more sensitive to lactose, such that the cell starts uptaking lactose and producing energy quickly.
Try to adjust the parameters using sliders, such the the cells divide faster when there is lactose outside.

## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Bain, C; Dabholkar, S (2016).  NetLogo Genetic Switch model.
* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2003 Uri Wilensky.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
true
0
Polygon -7500403 true true 180 15 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 285 165 285 225 285 225 15 180 15
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

complex
true
0
Polygon -2674135 true false 76 47 197 150 76 254 257 255 257 47
Polygon -10899396 true false 79 46 198 148 78 254

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

enzyme
true
0
Polygon -2674135 true false 76 47 197 150 76 254 257 255 257 47

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

hello
true
0

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

inhib complex
true
0
Polygon -2674135 true false 76 47 197 150 76 254 257 255 257 47
Polygon -1184463 true false 77 48 198 151 78 253 0 253 0 46

inhibitor
true
0
Polygon -1184463 true false 197 151 60 45 1 45 1 255 60 255

laci
true
0
Polygon -8630108 true false 120 120 135 135 150 135 165 120 270 120 270 180 210 180 210 210 165 210 165 180 120 180 120 210 75 210 75 180 15 180 15 120 120 120

laci-lactose-complex
true
9
Polygon -8630108 true false 15 135 15 210 150 210 270 210 270 135 165 135 150 150 135 150 120 135 75 135
Polygon -7500403 true false 135 150 150 150 165 135 150 120 135 120 120 135

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
15
Polygon -7500403 true false 150 90 90 135 120 195 180 195 210 135

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

protein
true
0
Polygon -7500403 false true 165 75 135 75 135 90 165 105 165 75 165 60 135 105 165 120 180 120 180 90 150 75 150 105 180 135 165 135 165 120 180 120 195 135 195 105 195 105 165 105 150 105 165 90 180 75 165 75 150 90 165 105 150 120 135 150 120 150 120 165 150 165 180 165 165 135 165 135
Polygon -7500403 false true 165 150 165 165 150 180 135 165 120 195 150 210 165 180 180 165 150 165 135 150 135 165 120 165 120 210 150 195 180 195 180 180 195 165 165 150 165 150 210 165 180 210 150 180 135 210 120 225 150 225
Polygon -7500403 false true 135 120 120 120 150 135 150 150 180 150 150 120 120 135 135 105 105 105 180 135 210 150 105 120 105 135 210 195

pump
true
0
Rectangle -2674135 true false 105 60 195 240

rnapol
true
10
Circle -13345367 true true 45 75 150
Circle -13345367 true true 105 75 150

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

substrate
true
5
Polygon -10899396 true true 76 47 197 151 75 256

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 6.0-M5
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
