class_name Alys extends CharacterBody2D

# --- REFERÊNCIAS AOS NÓS INTERNOS DA CENA ---
# Componente responsável pela movimentação de plataforma
@onready var godot_essentials_platformer_movement_component: GodotEssentialsPlatformerMovementComponent = $GodotEssentialsPlatformerMovementComponent
# Máquina de estados finitos que gerencia os estados do personagem (Idle, Walk, Morte, etc.)
@onready var godot_essentials_finite_state_machine: GodotEssentialsFiniteStateMachine = $GodotEssentialsFiniteStateMachine
# Nó visual do sprite animado do personagem
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
# Tocador de animação para gerenciar transições e eventos visuais
@onready var animation_player: AnimationPlayer = $AnimationPlayer
# Sensor RayCast2D para detectar quinas de plataformas e permitir escalada
@onready var ledge_climb_detector: RayCast2D = $LedgeClimbDetector
# Nó pai que agrupa efeitos visuais do próprio personagem
@onready var effects: Node2D = $Effects
# Referência ao nó do estado 'Idle' dentro da máquina de estados
@onready var idle: Idle = $GodotEssentialsFiniteStateMachine/Ground/Idle
# Referência ao nó Hurtbox (área de colisão do próprio jogador)
@onready var hurtbox: Area2D = $Hurtbox


# --- LIGAÇÃO DE OBJETOS EXTERNOS OU ESPECÍFICOS ---
# Exibe um campo no Inspetor do Godot para você arrastar e ligar qualquer objeto de partícula (GPUParticles2D)
@export var target_gpu_particles: GPUParticles2D

# --- CONTROLE DE VELOCIDADE DO AMOUNT_RATIO ---
# Duração (em segundos) para o amount_ratio ir de 0.0 até 1.0.
# Quanto maior esse valor, mais devagar a quantidade de partículas vai subir!
@export var particle_fade_duration: float = 3.0


# --- VARIÁVEIS DE CONTROLE ---
# Flag booleana para registrar se o personagem está virado para a esquerda
var is_left_direction: bool = false
# Controla o Tween que altera o amount_ratio gradualmente
var particle_tween: Tween


# Função executada uma única vez quando o nó entra na cena
func _ready():
	# Garante que as partículas ligadas e internas comecem desligadas e com amount_ratio em 0
	disable_effects()
	# Conecta o sinal de término de animação da AnimationPlayer à função local
	animation_player.animation_finished.connect(on_animation_player_finished)
	
	# Conecta os sinais de entrada e saída de área da Hurtbox via código
	if hurtbox:
		if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
			hurtbox.area_entered.connect(_on_hurtbox_area_entered)
		if not hurtbox.area_exited.is_connected(_on_hurtbox_area_exited):
			hurtbox.area_exited.connect(_on_hurtbox_area_exited)


# Função executada a cada frame de renderização (lógicas visuais)
func _process(delta):
	# Atualiza a inversão do sprite conforme o movimento
	_update_sprite_flip()
	# Ajusta a direção do raio detector de escalada
	_update_ledge_climb_detector()


# Atualiza a orientação horizontal (flip_h) do AnimatedSprite2D
func _update_sprite_flip():
	is_left_direction = godot_essentials_platformer_movement_component.last_faced_direction.x < 0
	
	if animated_sprite_2d.flip_h != is_left_direction:
		animated_sprite_2d.flip_h = is_left_direction


# Inverte a posição do detector de quinas com base na direção do personagem
func _update_ledge_climb_detector():
	if is_left_direction and ledge_climb_detector.target_position.x > 0:
		ledge_climb_detector.target_position *= -1
	elif not is_left_direction and ledge_climb_detector.target_position.x < 0:
		ledge_climb_detector.target_position *= -1


# Desativa a emissão de partículas e zera o amount_ratio
func disable_effects():
	if target_gpu_particles:
		target_gpu_particles.emitting = false
		target_gpu_particles.amount_ratio = 0.0 # Começa gerando 0% das partículas

	for effect in effects.get_children():
		if effect is CPUParticles2D or effect is GPUParticles2D:
			effect.emitting = false


# Aumenta o amount_ratio devagar de 0.0 até 1.0 ao entrar na área
func _fade_in_particles():
	if not target_gpu_particles:
		return

	# Cancela transições anteriores se ainda estiverem rodando
	if particle_tween and particle_tween.is_running():
		particle_tween.kill()

	# Liga a emissão
	target_gpu_particles.emitting = true

	# Anima a propriedade 'amount_ratio' de onde estiver até 1.0 no tempo de 'particle_fade_duration'
	particle_tween = create_tween()
	particle_tween.tween_property(target_gpu_particles, "amount_ratio", 1.0, particle_fade_duration)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)


# Diminui o amount_ratio devagar de 1.0 até 0.0 ao sair da área
func _fade_out_particles():
	if not target_gpu_particles:
		return

	# Cancela transições anteriores se ainda estiverem rodando
	if particle_tween and particle_tween.is_running():
		particle_tween.kill()

	# Anima o 'amount_ratio' até 0.0 no tempo de 'particle_fade_duration'
	particle_tween = create_tween()
	particle_tween.tween_property(target_gpu_particles, "amount_ratio", 0.0, particle_fade_duration)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
	
	# Desliga a emissão só depois que chegar a 0.0
	particle_tween.tween_callback(func(): target_gpu_particles.emitting = false)


# Sinal disparado quando uma Area2D ENTRA na caixa de colisão (Hurtbox) do personagem
func _on_hurtbox_area_entered(area: Area2D):
	# Verifica se a área tocada está configurada na Camada 11 (Layer 11)
	if area.get_collision_layer_value(11):
		# Inicia o aumento gradual de partículas até 1.0
		_fade_in_particles()
	else:
		# Se for outra área (sem a Camada 11), ativa a rotina de dano/morte
		animation_player.play("death")
		godot_essentials_finite_state_machine.lock_state_machine()


# Sinal disparado quando uma Area2D SAI da caixa de colisão (Hurtbox) do personagem
func _on_hurtbox_area_exited(area: Area2D):
	# Verifica se a área de onde o personagem acabou de sair estava na Camada 11 (Layer 11)
	if area.get_collision_layer_value(11):
		# Inicia a diminuição gradual de partículas até 0.0
		_fade_out_particles()


# Função disparada automaticamente quando qualquer animação da AnimationPlayer é concluída
func on_animation_player_finished(name: String):
	if name == "death":
		global_position = get_tree().get_first_node_in_group("respawn").global_position
		animated_sprite_2d.modulate.a = 1.0
		godot_essentials_finite_state_machine.current_state = idle
		godot_essentials_finite_state_machine.unlock_state_machine()
