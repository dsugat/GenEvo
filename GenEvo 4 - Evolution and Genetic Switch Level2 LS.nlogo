extensions [ls profiler]
breed [ecolis ecoli]
breed [p-lactoses p-lactose]
globals [
  n-models
  color-list
  baby?
  ctotal-lactose-outside
  lactose-quantity
  ini-energy
  model-number
]
ecolis-own [
  my-model
  my-var-list
  energy
  lactose-inside
  lactose-outside
  LacY-inside
  LacY-installed
  LacZ-inside
  LacI-lactose-complex
  child-lactose-around
  my-model-color-number
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; setup procedures ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ca
  ls:reset
  set-global-variables
  gen-bcells
  ask ecolis [
    ls:let my-cell-color (item my-model color-list)
    ls:let ini-energy-value ini-energy
    ls:ask my-model [
      set LevelSpace? true
      set-cell-color my-cell-color
      set ini-energy ini-energy-value
      set lactose? false           ;; Lactose in the individual models is controlled by the population model.
      setup
    ]
    ifelse glucose? [
      ls:ask my-model [
        set glucose? true
      ]
    ]
    [
      ls:ask my-model [
        set glucose? false
      ]
    ]
  ]
  p-add-lactose lactose-quantity
  reset-ticks
end

to set-global-variables
  set n-models number-of-models
  set color-list [5 17 35 45 55 85 115 125]
  set ini-energy 3000
  set lactose-quantity ( n-models * 3000 )
  set model-number 1
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; go procedures ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  die-cells
  ask ecolis [move]
  ask p-lactoses [move]
  reproduce-cells
  p-update-lactose
  ask ecolis [
    update-child-model
    ifelse glucose? [
      ls:ask my-model [
        set glucose? true
      ]
    ]
    [
      ls:ask my-model [
        set glucose? false
      ]
    ]
  ]
  if lactose? [ask patches [set pcolor 2]]
  if count ecolis = 0 [stop]
  tick
end

to update-child-model
  if lactose? [
    ls:let num-child-lactose-outside floor ( lactose-quantity / length ls:models )
    ls:ask my-model [
      update-lactose num-child-lactose-outside
    ]
  ]
  if glucose? [
    ls:ask my-model [set glucose? true]
  ]
  ls:ask my-model [
    go
  ]
end

; set var-name-list ["energy" "LacY-inside" "LacY-installed" "LacZ" "lacI-lacotose-complex" "lactose-inside" "lactose-outside"]
to extract-child-variables
  set my-var-list ([var-list] ls:of my-model)
  set energy item 0 my-var-list
  set LacY-inside item 1 my-var-list
  set LacY-installed item 2 my-var-list
  set LacZ-inside item 3 my-var-list
  set LacI-lactose-complex item 4 my-var-list
  set lactose-inside item 5 my-var-list
  set lactose-outside item 6 my-var-list
end

to gen-bcells
  repeat n-models [
    crt 1 [
      set breed ecolis
      set my-model-color-number model-number
      ls:load-headless-model "GenEvo 1 - Genetic Switch-LevelSpace-new.nlogo"
      set my-model last ls:models
      setxy random-xcor random-ycor
      set shape "ecoli"
      set color (item my-model color-list)
      set model-number model-number + 1
    ]
  ]
end

to p-add-lactose [num-lactose]
  if lactose? [
;    crt num-lactose [
;      set breed p-lactoses
;      setxy random-xcor random-ycor
;      set shape "lactose"
;      set color grey
;      set size 1
;    ]
    ask patches [set pcolor 2]
    ask ecolis [
      ls:let c-lactose-outside floor ( num-lactose / length ls:models )
      ls:ask my-model [add-lactose c-lactose-outside]
    ]
  ]
end

to p-update-lactose
  if not lactose? [
    set ctotal-lactose-outside 0
    ask ecolis [
      ls:ask my-model [create-var-list]
      extract-child-variables
      set ctotal-lactose-outside ctotal-lactose-outside + lactose-outside
    ]
    show ctotal-lactose-outside
    if ctotal-lactose-outside < (lactose-quantity / 2) [
      ask patches [set pcolor 1]
    ]
    if ctotal-lactose-outside = 0 [
      ask patches [set pcolor 0]
    ]
  ]
;  ifelse lactose? [
;    p-add-lactose (lactose-quantity - count p-lactoses)
;  ]
;  [
;    set ctotal-lactose-outside 0
;    ask ecolis [
;      ls:ask my-model [create-var-list]
;      extract-child-variables
;      set ctotal-lactose-outside ctotal-lactose-outside + lactose-outside
;    ]
;    show ctotal-lactose-outside
;    let lactose-diff ( count p-lactoses - ctotal-lactose-outside )
;    ifelse ( lactose-diff >= 0 )[
;      ask n-of lactose-diff p-lactoses [die]
;    ]
;    [
;      crt ( - lactose-diff ) [
;        set breed p-lactoses
;        setxy random-xcor random-ycor
;        set shape "lactose"
;        set color grey
;        set size 1
;      ]
;    ]
;  ]
end

to move
  rt random-float 360
  fd 1
end

to reproduce-cells
  ask ecolis [
    extract-child-variables
    if ( energy > 2 * ini-energy ) [
      ls:ask my-model [divide-cell]
      set energy energy / 2
      set LacY-inside LacY-inside / 2
      set LacY-installed lacY-installed / 2
      set LacZ-inside LacZ-inside / 2
      set LacI-lactose-complex LacI-lactose-complex / 2
      set lactose-inside lactose-inside / 2
      create-my-var-list
      ls:let my-cell-color [color] of self
      ls:let ini-energy-value ini-energy
      hatch 1 [
        rt random-float 360 fd 1
        ls:load-headless-model  "GenEvo 1 - Genetic Switch-LevelSpace-new.nlogo"
        set my-model last ls:models
        ls:let ini-LacY-installed LacY-installed
        ls:let ini-LacY LacY-inside
        ls:let ini-LacZ LacZ-inside
        ls:let ini-lactose-inside lactose-inside
        ls:let ini-lacI-lactose-complex lacI-lactose-complex
        ls:ask my-model [
          set-cell-color my-cell-color
          set LevelSpace? true
          set ini-energy ini-energy-value
          setup
          ask n-of ini-LacY-installed patches with [pcolor = cell-color] [set pcolor red]
          create-LacYs ini-LacY[
            setshape
            genXY-inside
          ]
          create-LacZs ini-LacZ[
            setshape
            genXY-inside
          ]
          create-lactoses ini-lactose-inside [
            setshape
            set inside? true
            genXY-inside
          ]
          ask n-of ini-lacI-lactose-complex LacIs [
            set partner one-of lactoses with [inside?]
            ask partner [ set partner myself ]
            setshape
            ask partner [ setshape ]
            if (bound-to-operator?) [
              set inhibited? false
              set bound-to-operator? false
              fd 1
            ]
          ]
        ]
        set baby? true
      ]
    ]
  ]
end

to die-cells
  ask ecolis [
    if energy < 0 [
      ls:close my-model
      die
    ]
  ]
end

to create-my-var-list
  set my-var-list ( list energy LacY-inside LacY-installed LacZ-inside LacI-lactose-complex lactose-inside lactose-outside )
end

to inspect-cell
  ifelse mouse-inside? [
    ask ecolis [ set pcolor 6 ]
  ]
  [
    ask ecolis [
      ifelse lactose? [
        set pcolor 2
      ]
      [
        if ctotal-lactose-outside < lactose-quantity / 2 [set pcolor 1]
        if ctotal-lactose-outside = 0 [set pcolor 0]
      ]
    ]
  ]
  if mouse-inside? and mouse-down? [
    if count ecolis-on patch mouse-xcor mouse-ycor > 0  [
      ask one-of ecolis-on patch mouse-xcor mouse-ycor [
        ls:show my-model
      ]
    ]
  ]
end

to load-models
end

; Copyright 2003 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
418
10
912
505
-1
-1
14.73
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
28
12
107
54
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
111
12
195
55
go
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
27
95
406
315
Cell Number
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"1" 1.0 0 -7500403 true "" "plot count ecolis with [color = 5]"
"2" 1.0 0 -1604481 true "" "plot count ecolis with [color = 17]"
"3" 1.0 0 -6459832 true "" "plot count ecolis with [color = 35]"
"4" 1.0 0 -1184463 true "" "plot count ecolis with [color = 45]"
"5" 1.0 0 -10899396 true "" "plot count ecolis with [color = 55]"
"6" 1.0 0 -11221820 true "" "plot count ecolis with [color = 85]"
"7" 1.0 0 -8630108 true "" "plot count ecolis with [color = 115]"
"8" 1.0 0 -5825686 true "" "plot count ecolis with [color = 125]"

PLOT
24
327
406
500
Lactose
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
"default" 1.0 0 -16777216 true "" "plot count p-lactoses"

SWITCH
208
13
304
46
lactose?
lactose?
1
1
-1000

SLIDER
209
52
407
85
number-of-models
number-of-models
1
8
3.0
1
1
NIL
HORIZONTAL

SWITCH
308
12
407
45
glucose?
glucose?
1
1
-1000

BUTTON
28
57
196
90
inspect cells
inspect-cell
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
939
30
1049
63
NIL
load-models
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
939
90
1188
256
model-paths
a\nb\nc\nd
1
1
String

@#$#@#$#@
## WHAT IS IT?

This model is a part of Genetics and Evolution introductory curriculum. It is to be used with LevelSpace extension of NetLogo.
It models competition for resources in asexually reproducing bacterium E. coli.

## HOW IT WORKS

This model is of population of E coli cells. Each cell in the population model correspond to a cell in an individual NetLogo model, Genetic Switch. 
An individual model simulates DNA-Protein interactions in lac-operon (Genetic Switch) of E. coli.
The completion for resources and survival of faster reproducing cell through natural and statistical selection is modeled. The cells with a 'fitter' genetic circuit can turn on and off the genetic switch faster. 

In the individual models, the The statistical selection (genetic drift) also plays an important role, as the molecular interactions at the cellular level in the child model are stochastic.
The energy of a cell is tracked. A cell divides when its energy   As a cell reproduces, daughter cells inherits genetic as well as epigenetic information from the parent cell.

## HOW TO USE IT

A facilitator should use it with other child models (Genetic Switch) saved in the same folder.
Child models should be named as “GenEvo 1 – Genetic Switch1.nlogo”, “GenEvo 1 – Genetic Switch2.nlogo” , “GenEvo 1 – Genetic Switch3.nlogo”  and so on.

This model on SETUP, sets up the parent model with E. coli cells of different types (represented with different colors) randomly distributed across the world. Each cell has a child model associated with it. The corresponding child models are also set-up.

### Buttons

SETUP - Sets up the model
GO - runs the simulation for parent and child models
ADD LACTOSE - Adds 2500 molecules of lactose (yellow pentagons) per child model

### Sliders

Number-of-models – A teacher can select the number of models

### Switches

Constant-lactose – If ON the lactose outside the cell is constant, which models an environment with abundant supply of lactose (not uncommon in nature for short amount of time).

## THINGS TO NOTICE

Notice the change in cell numbers and corresponding status of the switch in the child models

## HOW TO CITE

If you mention this model in a publication, we ask that you include the citation for the NetLogo software:

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

ecoli
true
0
Rectangle -7500403 true true 75 90 225 210
Circle -7500403 true true 15 90 120
Circle -7500403 true true 165 90 120

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

lactose
true
0
Polygon -7500403 true true 150 135 135 150 135 165 165 165 165 150 150 135

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
