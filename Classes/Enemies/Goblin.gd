
extends Node2D

var scn
var Name="Goblin"
var ID
var ready=true setget readiness
var ready_icon
var HP=2 setget change_hp
var Def=1 setget change_def
var Abilities={"Attack":"Dagger","Defence":"Block","Flee":"Flee"}
onready var sprite=load("res://Art Assets/Goblin.png")
var to_dead=true
var forfeit=false
var lbl_Def
var lbl_HP
var dead=false
var stagger=false

var afflictions={1:[],2:[],3:[]}
#for each number in afflictions, call the name of the affliction then move it down in duration. at the start of each turn. This will end stances

#on attack, call targeted(self,[types]) (or something similar) also add this to player abilities
func _ClearStagger():
	#enemy loses their turn
	#also call start turn to end stances and defences... or call stances separately
	stagger=false
	


func start_turn():
	Action()
	

func end_turn():
	for t in afflictions.keys():
		for a in afflictions[t]:
			call(a,t)
			afflictions[t].remove(afflictions[t].find(a))
			if t>1:
				afflictions[a-1].append(a)
	ready=false
	ready_icon.hide()

func bleeding(t):
	Damage(1)

func readiness(val):
	if not dead:
		ready=val
	#check stagger
		if val and stagger:
			ready=false
			stagger=false
		
	#	if ready:
	#		ready_icon.show()
	#	else:
	#		ready_icon.hide()

func change_def(val):
	
	Def = val
	
	check_flee()
	lbl_HP.set_text(str(HP))
	lbl_Def.set_text(str(Def))

func change_hp(val):
	HP=val
	check_alive()
	lbl_HP.set_text(str(HP))
	lbl_Def.set_text(str(Def))

func Damage(val):
	if Def==0:
		HP-=val
		lbl_HP.set_text(str(HP))
		check_alive()
	if Def>0:
		Def-=val
		lbl_Def.set_text(str(Def))
		print(Def)
		
	if Def <0:
		Def=0
		check_flee()
	lbl_HP.set_text(str(HP))
	lbl_Def.set_text(str(Def))
	
func check_alive():
	
	if HP<=0:
		get_parent().hide()
		dead=true
		ready=false
		#queue_free()
		#queuefree causes bugs, need to update all enemy lists to free. keep until end of scene then it can be used.
		#change sprite
		#make untargetable
		#end ai
func check_flee():
	if not to_dead:
		forfeit=true

func _ready():
	pass

func _connect():
	scn.get_node("PlayerActions").connect("ClearStagger",self,"_ClearStagger")

func set_bars(text_def,text_hp):
	lbl_Def=text_def
	lbl_HP=text_hp

###Abilities:
	###everything does 1 damage to health
#Goblin punch, 1 damage, 2 against players who have taken a turn
#Wild rush (reduce the defence of 3 players by 1)
#Panic. gain 3 defence, if defence is 0, 1 otherwise.
func Action():
	
	var scn=get_tree().get_current_scene()
	var not_dead_players=[]
	var pl_readies={}
	var pl_used=[]
	var ai_readies={}
	var pl_vuln={}
	var ai_vuln={}
	var pl_vuln2={}
	var pl_vuln3={}
	#get if players/ai have turns ready
	for r in scn.Friends.keys():
		pl_readies[r]=scn.Friends[r].ready
		if not scn.Friends[r].ready:
			pl_used.append(r)
		if not scn.Friends[r].forfeit and not scn.Friends[r].dead:
			not_dead_players.append(r)
	for ai in scn.Enemies.keys():
		ai_readies[ai]=scn.Friends[ai].ready
	
	
	for i in not_dead_players:
		if scn.Friends[i].dyn_Def==0:
			pl_vuln[i]=scn.Friends[i].HP
		elif scn.Friends[i].dyn_Def==1:
			pl_vuln2[i]=scn.Friends[i].HP
		else:
			pl_vuln[i]=200
	
	var targs=[]
	if Def==0:
		use_ability(3,0)
	else:
		for i in not_dead_players:
			if pl_vuln.has(i):
				targs.append(i)
		if targs.size()>0:
			use_ability(1,targs[randi()%targs.size()])
			#attack random target with goblin punch
		else:
			var semi_vuln=[]
			for i in not_dead_players:
				print(i)
				print(scn.Friends[i].Name)
				if scn.Friends[i].dyn_Def>=2 and not scn.Friends[i].ready:
					semi_vuln.append(i)
			var final_pair=[]
			if not scn.Friends[2].forfeit and not scn.Friends[2].dead:
				final_pair.append(2)
			if not scn.Friends[3].forfeit and not scn.Friends[3].dead:
				final_pair.append(2)
			#attack a random member of [goblin punch on semi_vuln, wild rush on final pair]
			if semi_vuln.size()>0 or final_pair.size()>0:
				var choice=randi()%(semi_vuln.size()+final_pair.size())
				if choice<semi_vuln.size():
					#attack semi_vuln[choice} with goblin punch
					use_ability(1,semi_vuln[choice])
				else:
					#attack final_pair[choice]
					use_ability(2,final_pair[choice])
			else:
				var choice=randi()%(not_dead_players.size()+1)
				if choice<not_dead_players.size():
					#goblin punch not_dead_players[choice]
					use_ability(1,not_dead_players[choice])
				else:
					#panic
					use_ability(3,0)
				
func use_ability(ability,target):
	##if an ability has two aspects (strike and poison) send each one individually
	#if not blocked, do it and check the next one. if it is, dont do it, but check the next one? do in cancelling order?
	#blocked poisoned strike, blocked strike stops poison, blocked poison does not stop strike
	#so run target(strike) then run target(poison). as soon as one fails, stop doing anything
	#lots of versatility here
	var scn=get_tree().get_current_scene()
	var blocked=false
	var not_dead_players=[]
	for i in scn.Friends.keys():
		if scn.Friends[i].ready:
			not_dead_players.append(i)
	if ability==1:##goblin punch
		print("Goblin Punch")
		blocked=scn.Friends[target].targeted(ID,"strike")
		if scn.Friends[target].dyn_Def<=0:
			if not scn.Friends[target].ready and not blocked:
				scn.Friends[target].HP-=2 #old code from when 2hp damage could be done, currently this will be converted to 1 damage on the character script
			elif not blocked:
				scn.Friends[target].HP-=1
		else:
			if not scn.Friends[target].ready and not blocked:
				scn.Friends[target].dyn_Def-=2
			elif not blocked:
				scn.Friends[target].dyn_Def-=1
			
	if ability==2:##Wild rush
		print("Wild Rush")
		var targs=[target]
		if not_dead_players.find(target-1)>=0:
			targs.append(target-1)
			print(target-1)
		if not_dead_players.find(target+1)>=0:
			targs.append(target+1)
			print(target +1)
		var blocked=[]
		
		for i in range(targs.size()):
			blocked.append(scn.Friends[targs[i]].targeted(ID,"strike"))
		
		for k in range(blocked.size()):
			if not blocked[k]:
				scn.Friends[targs[k]].dyn_Def=scn.Friends[targs[k]].dyn_Def-1
				
				
	if ability==3: #panic
		print("Panic")
		if Def==0:
			Def+=3
		else:
			Def+=1
	lbl_HP.set_text(str(HP))
	lbl_Def.set_text(str(Def))
	end_turn()


	
	
	#####get players' health and def. if players 1,2,3 or 2,3,4 all have 1 more more defence then wild rush them, prioritizing the lowest defs
	#if not to_death and def = o, flee.
	#if fled, do nothing
	#if a player has taken their action and has 0, def, use goblin punch
	#panic if def is 0
	#attack a player with 0 def
	#attack a used player with goblin punch
	#panic
