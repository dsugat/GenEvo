breed [ LacIs LacI ]  ;; LacI repressior protein (violet proteins)
breed [ LacZs LacZ ]  ;; LacZ beta-galactosidase emzyme (red proteins)
breed [ ONPGs ONPG ]  ;; ortho-Nitrophenyl-beta-galactoside (ONPG) molecule (grey molecules) that is cleaved by beta-galactosidase to produce an intensely yellow compound.
breed [ RNAPs RNAP ]  ;; RNA Polymerases (brown proteins) that bind to promoter part of DNA and synthesize mRNA from the downstream DNA

LacIs-own [
  partner             ;;  a partner is a ONPG molecule with which a LacI molecule binds to form a complex
  inhibitor?          ;;  a boolean to track if a LacI can bind to DNA as an inhibitor of transciption
]
RNAPs-own [on-dna?]   ;; a boolean to track if a RNAP is trascribing on DNA
ONPGs-own [
  partner             ;; a partner is a lacI molecule with which an ONPG forms a complex
]

globals
[ promoter-color-list       ;; color list to set promoter colors based on their strengths
  rbs-color-list            ;; color list to set rbs colors based on their strengths
  gene-color                ;; color of the gene
  operon-transcribed?       ;; a boolean to see if the operon is transcribed
  LACZ-PRODUCTION-NUM       ;; number of lacZ molecules produced per transcription (this number depends on the rbs strength)
  lacZ-production-num-list  ;; list of numbers to set lacZ molecules produced based on the rbs strength
  ONPG-degradation-count    ;; a variable to keep track of number of ONPG molecules degraded
  energy-value              ;; keeps track of the energy value of the cell
  lacI-number               ;; number of lacI molecules
  RNAP-number               ;; number of RNA Polemerase molecules
  inhibited?                ;; boolean for whether or not the operator is inhibited
  dna                       ;; agentset containing the patches that are DNA
  non-dna                   ;; agentset excluding the patches that are DNA
  lacZ-gene                 ;; agentset containing the patches that are LacZ gene
  promoter                  ;; agentset containing the patches that are for the promoter
  operator                  ;; agentset containing the patches that are for the operator
  rbs                       ;; agentset containing the patches that are for the rbs
  terminator                ;; agentset containing the patches that are for the terminator
  total-transcripts         ;; a variable to keep track of the number of transciption events
  total-proteins            ;; a veriable to keep track of the number of proteins produced
  ini-ONPG-number           ;; a veriable to set initial ONPG number. This number is set to 0 in the setup procedure. It is set to 200 in the 'Add ONPG' button.
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; Setup Procedures ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ca
  set-global-variables
  set-DNA-patches
  add-proteins
  set-rbs-effect
  reset-ticks
end

to set-global-variables
  set promoter-color-list [62 64 65 68]
  set rbs-color-list [12 14 15 17]
  set gene-color 95
  set lacI-number 30
  set RNAP-number 30
  set lacZ-production-num-list [2 3 4 6]
  set inhibited? false
  set ONPG-degradation-count 0
  set total-transcripts 0
  set ini-ONPG-number 0
  set operon-transcribed? false
end

to set-DNA-patches   ;; a procedure to set the DNA patches in the cell and assign appropriate colors based on their strengths
  ask patches [set pcolor white]
  set dna patches with [
    pxcor >= -40 and pxcor < 30 and pycor > 3 and pycor < 6
  ]
  set promoter patches with [
    pxcor >= -40 and pxcor < -26 and pycor > 3 and pycor < 6
  ]
  set operator ( patch-set
    patches with [ pxcor >= -26 and pxcor < -20 and pycor = 4 ]
  patches with [ pxcor = -26 and pycor = 5 ]
  patches with [ pxcor = -24 and pycor = 5 ]
  patches with [ pxcor = -23 and pycor = 5 ]
  patches with [ pxcor = -21 and pycor = 5 ]
  )

  set rbs patches with [
    pxcor >= -20 and pxcor < -15 and pycor > 3 and pycor < 6
  ]
  set lacZ-gene patches with [
    pxcor >= -15 and pxcor < 25 and pycor > 3 and pycor < 6
  ]
  set terminator patches with [
    pxcor >= 25 and pxcor < 30 and pycor > 3 and pycor < 6
  ]
  ask promoter [
    if promoter-strength = "strong" [
      set pcolor item 0 promoter-color-list
    ]
    if promoter-strength = "medium" [
      set pcolor item 1 promoter-color-list
    ]
    if promoter-strength = "reference" [
      set pcolor item 2 promoter-color-list
    ]
    if promoter-strength = "weak" [
      set pcolor item 3 promoter-color-list
    ]
  ]
  ask operator [
    set pcolor orange
  ]
  ask rbs [
    if rbs-strength = "strong" [
      set pcolor item 0 rbs-color-list
    ]
    if rbs-strength = "medium" [
      set pcolor item 1 rbs-color-list
    ]
    if rbs-strength = "reference" [
      set pcolor item 2 rbs-color-list
    ]
    if rbs-strength = "weak" [
      set pcolor item 3 rbs-color-list
    ]
  ]
  ask lacZ-gene [
    set pcolor gene-color
  ]
  ask terminator [
    set pcolor gray
  ]
  set non-dna patches with [pcolor = white]
end

to set-rbs-effect        ;; sets number of LacZ molecules produced per transcription event depedning on the rbs strength
   if rbs-strength = "weak" [
    set lacZ-production-num item 0 lacZ-production-num-list
  ]
  if rbs-strength = "reference" [
    set lacZ-production-num item 1 lacZ-production-num-list
  ]
  if rbs-strength = "medium" [
    set lacZ-production-num item 2 lacZ-production-num-list
  ]
  if rbs-strength = "strong" [
    set lacZ-production-num item 3 lacZ-production-num-list
  ]
end

to add-proteins        ;; part of the setup procedure to create and randomly place proteins inside the cell
  create-lacIs lacI-number [
    setxy random-xcor random-ycor
    set inhibitor? false
    set partner nobody
    setshape
  ]
  create-RNAPs RNAP-number [
    setxy random-xcor random-ycor
    set on-dna? false
    setshape
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; go procedures ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  go-lacIs
  go-RNAPs
  go-LacZs
  go-ONPGs
  check-transcription
  degrade-lacZ
  dissociate-complex
  recolor-patches
  ask turtles [
    setshape
  ]
  if timed-expt? [
    if ticks = 2500 [ stop ]
  ]
  update-ONPG
  tick
end

to random-walk    ;; a random walk procedure for the proteins and ONPG molecules in the cell
  rt random-float 360
  fd 1
end

to setshape        ;; a procedure to set shapes of the molecules
  if breed = LacIs
  [ set size 10
    ifelse partner = nobody
    [ set shape "laci"]
    [ set shape "laci-onpg-complex" set size 10 ]
  ]
  if breed = RNAPs
    [ set size 6
      set shape "RNAPol"
      set color brown]
  if breed = ONPGs
    [
      ifelse partner = nobody
      [
        set shape "pentagon"
        set color gray
        set hidden? false
      ]
      [
        set hidden? true
      ]
    ]
   if breed = LacZs
   [ set shape "protein"
     set color red
     set size 6]
end

to go-lacIs
   ;; If there is a LacI at the operator, set the transcription is inhibited.
  if not inhibited? [
    ask LacIs with [ member? patch-ahead 2 operator and partner = nobody] [
      set inhibitor? true
      set inhibited? true
      set heading 0
      setxy -23 6
    ]
  ]

ask LacIs with [inhibitor?] [
  if (random-float 10 < lacI-bond-leakage) [
    set inhibitor? false
    set inhibited? false
    fd 3
  ]
]
  ask LacIs with [not inhibitor?] [
   random-walk
  ]

  ask LacIs [
    if partner != nobody [ stop ]
    set partner one-of (other ONPGs-here with [partner = nobody])
    if partner = nobody [ stop ]
    if [partner] of partner != nobody [ set partner nobody stop ]  ;; just in case two lacIs grab the same partner
    ifelse random-float 1 < complex-formation-chance
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
  ]
end

to go-RNAPs    ;; If a RNAP is close or on the promoter (green) and the operator is open, change heading and move on the DNA towards the terminator.

if not inhibited? [
  ask RNAPs [
    if promoter-strength = "strong" [
      if member? patch-here promoter or member? patch-ahead 9 promoter [
        start-transcription
      ]
    ]
    if promoter-strength = "medium" [
      if member? patch-here promoter or member? patch-ahead 3 promoter [
        start-transcription
      ]
    ]
    if promoter-strength = "reference" [
      if member? patch-here promoter or member? patch-ahead 2 promoter [
        start-transcription
      ]
    ]
    if promoter-strength = "weak" [
      if member? patch-here promoter or member? patch-ahead 1 promoter [
        start-transcription
      ]
    ]
  ]
]

if any? RNAPS with [on-dna?] [
  ask RNAPs with [on-dna?] [
    fd 1
    if (member? patch-here terminator) [
      set operon-transcribed? true
      set on-dna? false
      rt random-float 360
      set total-transcripts total-transcripts + 1
    ]
  ]
]

ask RNAPs with [not on-dna?] [
  random-walk
]
end

to start-transcription    ;; a procedure for RNAPs
  setxy xcor 5
  set heading 90
  set on-dna? true
end

to go-lacZs
  ask lacZs [
    rt random-float 360
    fd 1
    if count ONPGs-here != 0 [
      if random-float 1 < ONPG-degradation-chance
      [ ask one-of ONPGs-here [ die ]
        set ONPG-degradation-count ONPG-degradation-count + 1
      ]
    ]
  ]
end

to go-ONPGs
  ask ONPGs [
    random-walk
  ]
end

to check-transcription
  if (operon-transcribed?) [
    create-lacZs lacZ-production-num [
      setxy random-xcor random-ycor
      setshape
    ]
    set total-proteins total-proteins + lacZ-production-num
    set operon-transcribed? false
  ]
end

to add-ONPG [ONPG-number]
   create-ONPGs ONPG-number [
    set partner nobody
    setxy random-xcor random-ycor
    setshape
   ]
end

to recolor-patches  ;; Change the color of the cell based on ONPG degradation
  ask non-dna [
    set pcolor scale-color yellow ( 1000 - ONPG-degradation-count ) 0 1000
  ]
end

to dissociate-complex  ;; Dissociate the LacI-ONPG complex
  ask LacIs with [partner != nobody] [
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
    fd -1
   ]
  ]
end

to degrade-LacZ
  ask LacZs [
    if random-float 1 < LacZ-degradation-chance [
      die
    ]
  ]
end

to update-ONPG
  if const-ONPG? [
    add-ONPG ( ini-ONPG-number - count ONPGs )
  ]
end

to-report number-of-transcripts-per-tick
  report precision ( total-transcripts / ticks * 1000 ) 1
end

to-report number-of-proteins-per-tick
  report precision ( total-proteins / ticks * 1000 ) 1
end
@#$#@#$#@
GRAPHICS-WINDOW
335
11
914
308
-1
-1
4.431
1
10
1
1
1
0
1
1
1
-64
64
-32
32
1
1
1
ticks
30.0

BUTTON
24
10
114
59
NIL
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
219
10
312
56
NIL
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

CHOOSER
23
110
148
155
promoter-strength
promoter-strength
"reference" "strong" "medium" "weak"
3

CHOOSER
23
161
148
206
rbs-strength
rbs-strength
"reference" "strong" "medium" "weak"
3

SLIDER
24
444
323
477
lacI-bond-leakage
lacI-bond-leakage
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
24
481
323
514
complex-formation-chance
complex-formation-chance
0
1
0.95
0.01
1
NIL
HORIZONTAL

BUTTON
119
10
212
58
Add ONPG
set ini-ONPG-number 200\nadd-ONPG ini-ONPG-number
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
345
444
636
477
ONPG-degradation-chance
ONPG-degradation-chance
0
1
0.95
0.01
1
NIL
HORIZONTAL

PLOT
24
215
323
439
beta-galactosidase activity
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
"default" 1.0 0 -16777216 true "" "plot ONPG-degradation-count"

TEXTBOX
429
348
946
414
Promoter                 Operator                  RBS\n\nLacZ Gene               Terminator
14
0.0
1

TEXTBOX
362
289
430
431
-
100
65.0
1

TEXTBOX
523
289
548
431
-
100
25.0
1

TEXTBOX
655
289
679
433
-
100
15.0
1

TEXTBOX
362
324
429
466
-
100
95.0
1

TEXTBOX
524
324
548
466
-
100
5.0
1

SLIDER
345
480
635
513
complex-separation-chance
complex-separation-chance
0
0.01
1.0E-4
0.0001
1
NIL
HORIZONTAL

MONITOR
154
157
321
206
Translation Rate (Scaled)
number-of-proteins-per-tick
17
1
12

MONITOR
154
107
321
156
Transcription Rate (Scaled)
number-of-transcripts-per-tick
17
1
12

SWITCH
23
66
148
99
timed-expt?
timed-expt?
1
1
-1000

MONITOR
197
351
309
396
beta-gal activity
ONPG-degradation-count
17
1
11

SWITCH
175
66
298
99
const-ONPG?
const-ONPG?
0
1
-1000

SLIDER
655
444
916
477
lacZ-degradation-chance
lacZ-degradation-chance
0
1
0.003
0.001
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

It is a multi-agent model of a genetic circuit in a bacterial cell. This model is extension of the Genetic Switch Model in the GenEvo Systems Biology Curriculum. It incorporates synthetic biology aspects of designing and testing a genetic circuit.


## HOW IT WORKS

The components of the model are - a lac promoter with an operator, an RBS, a lacZ gene, a terminator, RNA polymerases, LacI repressor proteins and ONPG molecules.

The model explicitly incorporates transcription and implicitly incorporates translation.

A user can select promoter strength and RBS strength, add IPTG and run the model. The model simulates interactions between the components of the genetic circuit that results in an emergent cellular behavior. The cellular behavior of interest in this model is LacZ (beta-galactosidase) activity which can be observed in a graph and is also represented in the change in the color of the cell to yellow. Beta-galactosidase cleaves ONPG to produce an intensely yellow colored compound.

## HOW TO USE IT

Select the promoter strength and RBS strength.
Press SETUP to initialize the components in the model.
Press GO to run the model. The button ADD ONPG can be pressed to add ONPG.

‘Timed-expt?’ is a switch that runs the model to 2500 time units called ticks. This switch can be used to compare behavior of the cell in different runs of the same condition or different conditions (by varying promoter strength and RBS strengths).

‘Const-ONPG?’ is a switch which keeps ONPG concentration constant in a simulation run. This switch can be used to simulate the situations when ONPG concentration in the medium is excess and not a limiting factor.

## THINGS TO NOTICE

Run the model with a set PROMOTER-STRENGTH and RBS-STRENGTH and observe changes in the scaled transcription and translation rates. Also, observe changes in the LacZ activity in the graph as well as in the simulation.
Run it multiple times and observe the differences.

## THINGS TO TRY
Change the PROMOTER-STRENGTH and RBS-STRENGTH combination and observe the behavior again. See which combination has the most robust and optimum behavior.
Change the parameter values of lacI-bond-leackage, ONPG-degradation-chance, complex-separation-chance, complex-formation-chance, complex-separation-chance, LacZ-degradation-chance, and see how that affects the behavior of the model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

• Dabholkar S. & Wilensky, U. (2016).  NetLogo Genetic Switch Synthetic Biology Model.  http://ccl.northwestern.edu/netlogo/models/GeneticSwitchSyntheticBiology.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

The above link may be temporarily unavailable. Alternatively, you may find a copy of this model to the following link:
http://modelingcommons.org/browse/one_model/4759#model_tabs_browse_nlw

Please cite the NetLogo software as:

• Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
To cite the GenEvo Systems Biology curriculum as a whole, please use:
Dabholkar S. & Wilensky, U. (2016). GenEvo Curriculum. http://ccl.northwestern.edu/curriculum/genevo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2016 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.
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
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

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

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

laci
true
0
Polygon -8630108 true false 120 120 135 135 150 135 165 120 270 120 270 180 210 180 210 210 165 210 165 180 120 180 120 210 75 210 75 180 15 180 15 120 120 120

laci-lactose-complex
true
0
Polygon -8630108 true false 75 105 15 210 150 210 285 210 225 105 180 105 165 120 135 120 120 105 75 105
Polygon -1184463 true false 135 120 165 120 195 90 150 60 105 90 135 120

laci-onpg-complex
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
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

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

rnapol
true
10
Circle -13345367 true true 45 75 150
Circle -13345367 true true 105 75 150

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0-M9
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2500"/>
    <metric>ONPG-degradation-count</metric>
    <enumeratedValueSet variable="ONPG-degradation-chance">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="const-ONPG?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timed-expt?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="promoter-strength">
      <value value="&quot;reference&quot;"/>
      <value value="&quot;strong&quot;"/>
      <value value="&quot;medium&quot;"/>
      <value value="&quot;weak&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complex-separation-chance">
      <value value="1.0E-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complex-formation-chance">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lacI-bond-leakage">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lacZ-degradation-chance">
      <value value="0.003"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rbs-strength">
      <value value="&quot;reference&quot;"/>
      <value value="&quot;strong&quot;"/>
      <value value="&quot;medium&quot;"/>
      <value value="&quot;weak&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
0
@#$#@#$#@
