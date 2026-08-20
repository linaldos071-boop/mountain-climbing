class_name InteractiveNode2D extends Node2D

# --- REFERÊNCIAS AOS NÓS FILHOS DA CENA ---
# Nó responsável pela física sólida (impede a passagem do jogador/corpos)
@onready var static_body_2d: StaticBody2D = $StaticBody2D
# Nó detector de colisão (escuta quando algo encosta no objeto)
@onready var area_2d: Area2D = $Area2D
# Tocador de animação (AnimationPlayer)
@onready var animation_player: AnimationPlayer = $AnimationPlayer
# Tocador de animação via sprite (AnimatedSprite2D), caso utilize
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


# --- CONFIGURAÇÕES NO INSPECTOR ---
# Nome da animação que toca quando o objeto é atingido
@export var active_animation_name: String = "activated"
# Nome da animação padrão (idle) para a qual ele retorna
@export var default_animation_name: String = "activated_2"
# Camada física do objeto que vai ativar a reação (Camada 6 por padrão)
@export var trigger_layer: int = 6


# --- VARIÁVEIS DE CONTROLE ---
# Impede que a animação reative antes de terminar o ciclo
var is_active: bool = false


func _ready():
	# Conecta o sinal de impacto da Area2D
	if area_2d:
		area_2d.body_entered.connect(_on_body_entered)

	# Conecta os finais de animação dos tocadores
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
	if animated_sprite_2d:
		animated_sprite_2d.animation_finished.connect(_on_animated_sprite_finished)

	# Coloca o objeto na animação padrão ao iniciar o jogo
	_play_default_animation()


# Disparado quando um corpo físico encosta na Area2D deste objeto
func _on_body_entered(body: Node):
	if is_active:
		return

	# Checa se o corpo que bateu pertence à Camada 6
	if body is CollisionObject2D and body.get_collision_layer_value(trigger_layer):
		_activate_object()


# Inicia a animação de ativação
func _activate_object():
	is_active = true

	if animation_player and animation_player.has_animation(active_animation_name):
		animation_player.play(active_animation_name)
	elif animated_sprite_2d and animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation(active_animation_name):
		animated_sprite_2d.play(active_animation_name)


# Chamado automaticamente quando a animação do AnimationPlayer encerra
func _on_animation_finished(anim_name: String):
	if anim_name == active_animation_name:
		_play_default_animation()
		is_active = false


# Chamado automaticamente quando a animação do AnimatedSprite2D encerra
func _on_animated_sprite_finished():
	if animated_sprite_2d and animated_sprite_2d.animation == active_animation_name:
		_play_default_animation()
		is_active = false


# Retorna o objeto para a animação default
func _play_default_animation():
	if animation_player and animation_player.has_animation(default_animation_name):
		animation_player.play(default_animation_name)
	elif animated_sprite_2d and animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation(default_animation_name):
		animated_sprite_2d.play(default_animation_name)
