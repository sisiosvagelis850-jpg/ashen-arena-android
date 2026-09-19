extends Node3D

var player: Node3D
var boss: Node3D
var player_arm: Node3D
var player_weapon: Node3D
var boss_arm: Node3D
var boss_weapon: Node3D
var hud: CanvasLayer
var inventory: Control
var boss_bar: ProgressBar
var player_bar: ProgressBar
var stamina_bar: ProgressBar
var boss_name: Label
var status_label: Label
var player_hp := 260.0
var player_max := 260.0
var stamina := 120.0
var boss_hp := 680.0
var boss_max := 680.0
var boss_timer := 2.2
var busy := false
var blocking := false
var invulnerable := false
var fight_over := false
var boss_index := 0
var equipped_weapon := "Iron Vow Blade"
var equipped_set := "Cinder Warden Set"
var equipped_parts := {}

var bosses = [
	{"name":"THE CINDER WARDEN","title":"Keeper of the Last Pyre","hp":680.0,"damage":22.0,"color":Color("#8f2d1d")},
	{"name":"BELL-TOWER PENITENT","title":"The Chained Colossus","hp":960.0,"damage":32.0,"color":Color("#596168")},
	{"name":"THE PALE HUNTRESS","title":"Daughter of the White Veil","hp":590.0,"damage":25.0,"color":Color("#9bc1c7")}
]

var weapon_groups = {
	"Daggers":["Grave Needle","Ashen Fang","Widow's Mercy"],
	"Straight Swords":["Iron Vow Blade","Cinder Knight Sword","Moonlit Oath"],
	"Greatswords":["Grave Greatsword","Warden's Brand","Black Reliquary"],
	"Ultra Greatswords":["Colossus Slab","Cathedral Breaker","Pyre Monument"],
	"Curved Swords":["Pale Crescent","Mire Dancer","Sable Talon"],
	"Katanas":["White Veil","Bloodless Dawn","Shattered Moon"],
	"Thrusting Swords":["Penitent Thorn","Ivory Estoc","Starved Rapier"],
	"Axes":["Cinder Hatchet","Gallows Axe","Pilgrim Cleaver"],
	"Greataxes":["Bell-Tower Greataxe","Ash Monarch","Executioner's Eclipse"],
	"Hammers":["Reliquary Mace","Iron Psalm","Ember Hammer"],
	"Great Hammers":["Bell Hammer","Tomb Anvil","Last Cathedral"],
	"Spears":["Huntress Pike","Ashen Lance","Mire Spear"],
	"Halberds":["Warden Halberd","Gloom Reaper","Royal Ruin"],
	"Scythes":["Pale Harvest","Grave Moon","Silent Requiem"],
	"Twinblades":["Pale Twinblades","Cinder Spiral","Glass Tempest"],
	"Fists & Claws":["Penitent Fists","Wraith Claws","Iron Knuckles"],
	"Whips":["Thorn Litany","Ashen Chain","Widow Cord"],
	"Bows & Crossbows":["Veil Longbow","Tower Arbalest","Cinder Crossbow"],
	"Catalysts":["Ember Focus","Pale Chime","Grave Scepter"]
}

var armor_sets = {
	"Cinder Warden Set":["Cinder Warden Helm","Cinder Warden Cuirass","Cinder Warden Gauntlets","Cinder Warden Legguards","Cinder Warden Sabatons"],
	"Bell-Tower Penitent Set":["Penitent Iron Mask","Penitent Chainplate","Penitent Manacles","Penitent Leg Irons","Penitent Greaves"],
	"Pale Huntress Set":["Pale Huntress Hood","Pale Huntress Garb","Pale Huntress Gloves","Pale Huntress Trousers","Pale Huntress Boots"],
	"Grave Pilgrim Set":["Grave Pilgrim Cowl","Grave Pilgrim Mantle","Grave Pilgrim Wraps","Grave Pilgrim Leggings","Grave Pilgrim Boots"],
	"Glass Pontiff Set":["Glass Pontiff Crown","Glass Pontiff Vestment","Glass Pontiff Bracers","Glass Pontiff Skirt","Glass Pontiff Shoes"],
	"Mire Crown Set":["Mire Crown Helm","Mire Crown Carapace","Mire Crown Grips","Mire Crown Cuisses","Mire Crown Treads"]
}

func _ready():
	RenderingServer.set_default_clear_color(Color("#050404"))
	_build_world()
	_build_fighters()
	_build_ui()
	_equip_set("Cinder Warden Set")
	_reset_fight()

func mat(color: Color, metallic := 0.35) -> StandardMaterial3D:
	var m=StandardMaterial3D.new()
	m.albedo_color=color
	m.metallic=metallic
	m.roughness=.62
	return m

func mesh_part(parent: Node3D, mesh: PrimitiveMesh, pos: Vector3, scale_value: Vector3, color: Color, part_name: String) -> MeshInstance3D:
	var n=MeshInstance3D.new()
	n.name=part_name
	n.mesh=mesh
	n.position=pos
	n.scale=scale_value
	n.material_override=mat(color)
	parent.add_child(n)
	return n

func _build_world():
	var world=WorldEnvironment.new()
	var env=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("#080606")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("#60443a")
	env.ambient_light_energy=1.1
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world.environment=env
	add_child(world)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-52,-28,0)
	sun.light_color=Color("#ffd1a0")
	sun.light_energy=1.5
	sun.shadow_enabled=true
	add_child(sun)
	var floor=MeshInstance3D.new()
	var cyl=CylinderMesh.new();cyl.top_radius=8;cyl.bottom_radius=8;cyl.height=.4
	floor.mesh=cyl;floor.position.y=-.2;floor.material_override=mat(Color("#211613"),0.05)
	add_child(floor)
	for i in range(10):
		var pillar=MeshInstance3D.new();var box=BoxMesh.new();box.size=Vector3(.65,5,.65)
		pillar.mesh=box
		var a=float(i)/10.0*TAU
		pillar.position=Vector3(cos(a)*7.2,2.3,sin(a)*7.2)
		pillar.material_override=mat(Color("#171213"),0.0)
		add_child(pillar)
	var cam=Camera3D.new()
	cam.position=Vector3(0,3.1,8.7)
	cam.rotation_degrees=Vector3(-10,0,0)
	cam.current=true
	add_child(cam)

func make_fighter(name_text:String,color:Color,is_boss:bool) -> Node3D:
	var rig=Node3D.new();rig.name=name_text;add_child(rig)
	var armor=color
	mesh_part(rig,CapsuleMesh.new(),Vector3(0,1.7,0),Vector3(.72,.9,.55),armor,"Chest")
	mesh_part(rig,CapsuleMesh.new(),Vector3(0,2.9,0),Vector3(.48,.48,.48),armor.lightened(.1),"Helmet")
	mesh_part(rig,BoxMesh.new(),Vector3(0,2.9,-.38),Vector3(.58,.12,.12),Color("#0b0909"),"Visor")
	mesh_part(rig,BoxMesh.new(),Vector3(-.36,.72,0),Vector3(.32,1.0,.35),armor.darkened(.12),"LeftLeg")
	mesh_part(rig,BoxMesh.new(),Vector3(.36,.72,0),Vector3(.32,1.0,.35),armor.darkened(.12),"RightLeg")
	var left=Node3D.new();left.name="LeftArm";left.position=Vector3(-.86,2.15,0);rig.add_child(left)
	mesh_part(left,CapsuleMesh.new(),Vector3.ZERO,Vector3(.22,.7,.22),armor,"Gauntlet")
	var right=Node3D.new();right.name="RightArm";right.position=Vector3(.86,2.15,0);rig.add_child(right)
	mesh_part(right,CapsuleMesh.new(),Vector3.ZERO,Vector3(.22,.7,.22),armor,"Gauntlet")
	var weapon=Node3D.new();weapon.name="Weapon";weapon.position=Vector3(0,-.45,0);right.add_child(weapon)
	mesh_part(weapon,BoxMesh.new(),Vector3(0,-.75,0),Vector3(.12,1.35,.12),Color("#b9b4a9"),"Blade")
	mesh_part(weapon,BoxMesh.new(),Vector3(0,-.08,0),Vector3(.52,.09,.16),Color("#8a5b35"),"Guard")
	if is_boss:
		rig.scale=Vector3(1.18,1.18,1.18)
	return rig

func _build_fighters():
	player=make_fighter("Wanderer",Color("#354657"),false)
	player.position=Vector3(0,0,2.1)
	player.rotation_degrees.y=180
	player_arm=player.get_node("RightArm")
	player_weapon=player.get_node("RightArm/Weapon")
	boss=make_fighter("Boss",bosses[0].color,true)
	boss.position=Vector3(0,0,-2.0)
	boss_arm=boss.get_node("RightArm")
	boss_weapon=boss.get_node("RightArm/Weapon")

func ui_button(text_value:String,size:Vector2) -> Button:
	var b=Button.new();b.text=text_value;b.custom_minimum_size=size
	b.add_theme_font_size_override("font_size",18)
	return b

func _build_ui():
	hud=CanvasLayer.new();add_child(hud)
	var root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.add_child(root)
	boss_name=Label.new();boss_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	boss_name.position=Vector2(340,12);boss_name.size=Vector2(600,42);boss_name.add_theme_font_size_override("font_size",28);root.add_child(boss_name)
	boss_bar=ProgressBar.new();boss_bar.position=Vector2(300,55);boss_bar.size=Vector2(680,22);boss_bar.show_percentage=false;root.add_child(boss_bar)
	player_bar=ProgressBar.new();player_bar.position=Vector2(24,24);player_bar.size=Vector2(265,18);player_bar.show_percentage=false;root.add_child(player_bar)
	stamina_bar=ProgressBar.new();stamina_bar.position=Vector2(24,48);stamina_bar.size=Vector2(265,14);stamina_bar.show_percentage=false;root.add_child(stamina_bar)
	status_label=Label.new();status_label.position=Vector2(390,82);status_label.size=Vector2(500,40);status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;root.add_child(status_label)
	var block=ui_button("BLOCK",Vector2(135,82));block.position=Vector2(965,585);root.add_child(block)
	block.button_down.connect(func(): blocking=true)
	block.button_up.connect(func(): blocking=false)
	var light=ui_button("LIGHT ATTACK",Vector2(155,82));light.position=Vector2(1105,500);root.add_child(light);light.pressed.connect(_light_attack)
	var heavy=ui_button("HEAVY ATTACK",Vector2(155,82));heavy.position=Vector2(1105,595);root.add_child(heavy);heavy.pressed.connect(_heavy_attack)
	var dodge_left=ui_button("◀",Vector2(100,130));dodge_left.position=Vector2(10,285);root.add_child(dodge_left);dodge_left.pressed.connect(func():_dodge(-1))
	var dodge_right=ui_button("▶",Vector2(100,130));dodge_right.position=Vector2(1170,285);root.add_child(dodge_right);dodge_right.pressed.connect(func():_dodge(1))
	var inv=ui_button("INVENTORY",Vector2(165,58));inv.position=Vector2(20,635);root.add_child(inv);inv.pressed.connect(_toggle_inventory)
	var next=ui_button("NEXT BOSS",Vector2(165,58));next.position=Vector2(200,635);root.add_child(next);next.pressed.connect(_next_boss)
	_build_inventory(root)

func _build_inventory(root:Control):
	inventory=PanelContainer.new();inventory.position=Vector2(430,115);inventory.size=Vector2(820,570);inventory.visible=false;root.add_child(inventory)
	var outer=VBoxContainer.new();inventory.add_child(outer)
	var title=Label.new();title.text="WANDERER INVENTORY — ALL ITEMS UNLOCKED";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",24);outer.add_child(title)
	var tabs=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;outer.add_child(tabs)
	var weapons=TabContainer.new();weapons.name="Weapons";tabs.add_child(weapons)
	for group in weapon_groups:
		var scroll=ScrollContainer.new();scroll.name=group
		var box=VBoxContainer.new();scroll.add_child(box)
		for item in weapon_groups[group]:
			var b=ui_button(item+"  —  EQUIP",Vector2(620,46));box.add_child(b);b.pressed.connect(_equip_weapon.bind(item))
		weapons.add_child(scroll)
	var sets=ScrollContainer.new();sets.name="Armor Sets";tabs.add_child(sets)
	var setbox=VBoxContainer.new();sets.add_child(setbox)
	for set_name in armor_sets:
		var label=Label.new();label.text=set_name+"  |  "+", ".join(armor_sets[set_name]);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;setbox.add_child(label)
		var b=ui_button("EQUIP FULL "+set_name.to_upper(),Vector2(650,45));setbox.add_child(b);b.pressed.connect(_equip_set.bind(set_name))
	var pieces=TabContainer.new();pieces.name="Armor Pieces";tabs.add_child(pieces)
	var piece_names=["Helmets","Chest Armor","Gauntlets","Leg Armor","Boots"]
	for idx in range(piece_names.size()):
		var scroll=ScrollContainer.new();scroll.name=piece_names[idx]
		var box=VBoxContainer.new();scroll.add_child(box)
		for set_name in armor_sets:
			var item=armor_sets[set_name][idx]
			var b=ui_button(item+"  —  EQUIP",Vector2(620,45));box.add_child(b);b.pressed.connect(_equip_piece.bind(idx,item))
		pieces.add_child(scroll)
	var close=ui_button("CLOSE INVENTORY",Vector2(300,50));outer.add_child(close);close.pressed.connect(_toggle_inventory)

func _process(delta):
	if not fight_over and not inventory.visible:
		stamina=min(120.0,stamina+delta*(7.0 if blocking else 21.0))
		boss_timer-=delta
		if boss_timer<=0 and not busy:
			_boss_attack()
			boss_timer=2.0+randf_range(.2,1.0)
	player_bar.value=player_hp/player_max*100
	stamina_bar.value=stamina/120.0*100
	boss_bar.value=boss_hp/boss_max*100

func _light_attack():
	if busy or fight_over or inventory.visible or stamina<14:return
	stamina-=14;await _attack_anim(false)

func _heavy_attack():
	if busy or fight_over or inventory.visible or stamina<32:return
	stamina-=32;await _attack_anim(true)

func _attack_anim(heavy:bool):
	busy=true
	var t=create_tween();t.tween_property(player_arm,"rotation_degrees:z",-125.0,.24 if not heavy else .42).set_trans(Tween.TRANS_BACK)
	await t.finished
	boss_hp=max(0,boss_hp-(58 if heavy else 31))
	var hit=create_tween();hit.tween_property(boss,"position:x",.18,.06);hit.tween_property(boss,"position:x",0.0,.1)
	await hit.finished
	var r=create_tween();r.tween_property(player_arm,"rotation_degrees:z",0.0,.25)
	await r.finished
	busy=false
	if boss_hp<=0:_finish("VICTORY — ASH CLAIMED")

func _boss_attack():
	if busy or fight_over:return
	busy=true;status_label.text="DODGE OR BLOCK!"
	var t=create_tween();t.tween_property(boss_arm,"rotation_degrees:z",125.0,.55).set_trans(Tween.TRANS_BACK)
	await t.finished
	if not invulnerable:
		var damage=bosses[boss_index].damage*(.22 if blocking else 1.0)
		player_hp=max(0,player_hp-damage)
		var hit=create_tween();hit.tween_property(player,"position:z",2.35,.07);hit.tween_property(player,"position:z",2.1,.12)
		await hit.finished
	var r=create_tween();r.tween_property(boss_arm,"rotation_degrees:z",0.0,.3)
	await r.finished
	status_label.text=bosses[boss_index].title;busy=false
	if player_hp<=0:_finish("DEFEATED — TAP NEXT BOSS TO RETRY")

func _dodge(direction:int):
	if busy or fight_over or inventory.visible or stamina<25:return
	stamina-=25;busy=true;invulnerable=true
	var original=player.position.x
	var t=create_tween();t.tween_property(player,"position:x",float(direction)*1.6,.16).set_trans(Tween.TRANS_QUAD);t.tween_property(player,"position:x",original,.2)
	await t.finished
	invulnerable=false;busy=false

func _equip_weapon(item:String):
	equipped_weapon=item
	status_label.text="EQUIPPED: "+item
	var scale_value=1.0
	if "Great" in item or "Hammer" in item or "Monument" in item:scale_value=1.35
	player_weapon.scale=Vector3(scale_value,scale_value,scale_value)

func _equip_set(set_name:String):
	equipped_set=set_name
	for i in range(5):equipped_parts[i]=armor_sets[set_name][i]
	status_label.text="EQUIPPED FULL SET: "+set_name
	var colors={"Cinder Warden Set":Color("#773526"),"Bell-Tower Penitent Set":Color("#56616a"),"Pale Huntress Set":Color("#8eabb1"),"Grave Pilgrim Set":Color("#463d48"),"Glass Pontiff Set":Color("#756c8f"),"Mire Crown Set":Color("#526b3f")}
	var color=colors.get(set_name,Color("#354657"))
	for child in player.get_children():
		if child is MeshInstance3D and child.name!="Visor":child.material_override=mat(color)

func _equip_piece(index:int,item:String):
	equipped_parts[index]=item
	status_label.text="EQUIPPED: "+item

func _toggle_inventory():
	inventory.visible=not inventory.visible
	status_label.text="AVATAR EQUIPMENT PREVIEW" if inventory.visible else bosses[boss_index].title

func _next_boss():
	boss_index=(boss_index+1)%bosses.size()
	boss.queue_free()
	boss=make_fighter("Boss",bosses[boss_index].color,true);boss.position=Vector3(0,0,-2)
	boss_arm=boss.get_node("RightArm");boss_weapon=boss.get_node("RightArm/Weapon")
	_reset_fight()

func _reset_fight():
	player_hp=player_max;stamina=120;boss_max=bosses[boss_index].hp;boss_hp=boss_max;boss_timer=2.1;fight_over=false;busy=false
	boss_name.text=bosses[boss_index].name;status_label.text=bosses[boss_index].title

func _finish(message:String):
	fight_over=true;status_label.text=message
