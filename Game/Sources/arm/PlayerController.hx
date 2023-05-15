package arm;

import iron.math.Vec4;
import iron.object.CameraObject;
import iron.system.Input;
import armory.trait.physics.RigidBody;
import iron.object.BoneAnimation;
import iron.object.Object;
import kha.input.KeyCode;
import iron.object.Transform;
import iron.system.Input.Keyboard;
import armory.trait.physics.PhysicsWorld;
import armory.trait.ThirdPersonController;

// Направление движения вперёд/назад
enum MoveDirection {
	None;
	Forward;
	Backward;
}

// Боковое направление влево/вправо
enum SideDirection {
	None;
	Left;
	Right;
}

// Состояние анимации
enum AnimationState {
	Atack;
	Block;
	Idle;
	Walk(move:MoveDirection, side:SideDirection);
	Run(move:MoveDirection);
	Roll(move:MoveDirection, side:SideDirection);
}

// Контроллер игрока
class PlayerController extends iron.Trait {
	// Скорость вращения камеры
	static inline var rotationSpeed = 1.0;

	// Состояние анимации
	var animState = AnimationState.Idle;

	// Анимации
	var animation:BoneAnimation;

	// Физическое тело
	var body:RigidBody;

	// Камера
	var camera:Object;

	// Позиция/вращание и scale объекта
	var transform:Transform;

	var xVec = Vec4.xAxis();
	var zVec = Vec4.zAxis();

	// Возвращает анимацию объекта
	function getAnimimation(o:Object):BoneAnimation {
		if (o.animation != null)
			return cast o.animation;
		for (c in o.children) {
			var co = getAnimimation(c);
			if (co != null)
				return co;
		}
		return null;
	}

	// Возвращает физическое тело
	function getRigidBody(o:Object):RigidBody {
		var b = o.getTrait(RigidBody);
		if (b != null)
			return b;

		for (c in o.children) {
			var co = getRigidBody(c);
			if (co != null)
				return co;
		}

		return null;
	}

	// Запускает анимацию
	function playAnimation(name:String, onEnd:Void->Void = null, blend = 0.4) {
		if (animation.action != name)
			animation.play(name, onEnd, blend);
	}

	// Обновляет состояние анимации
	function updateAnimState() {
		switch (animState) {
			case Atack:
				playAnimation("Attack1_Player", () -> animState = Idle);
			case Block:
				playAnimation("Block1_Player");
			case Walk(move, side):
				switch (move) {
					case None:
						switch (side) {
							case None:
								playAnimation("Idle_Player");
							case Left:
								playAnimation("JogLeft_Player");
							case Right:
								playAnimation("JogRight_Player");
						}
					case Forward:
						switch (side) {
							case None:
								playAnimation("Walk_Player");
							case Left:
								playAnimation("JogForwardLeft_Player");
							case Right:
								playAnimation("JogForwardRight_Player");
						}
					case Backward:
						switch (side) {
							case None:
								playAnimation("WalkBack_Player");
							case Left:
								playAnimation("JogBackwardLeft_Player");
							case Right:
								playAnimation("JogBackwardRight_Player");
						}
				}
			case Run(move):
				switch (move) {
					case None:
						playAnimation("Idle_Player");
					case Forward:
						playAnimation("Run_Player");
					case Backward:
						playAnimation("Idle_Player");
				}
			default:
				playAnimation("Idle_Player");
		}
	}

	// Обрабатывает состояние события клавиатуры и мыши
	function updateInput() {
		var kb = iron.system.Input.getKeyboard();
		var mo = iron.system.Input.getMouse();

		switch (animState) {
			case Atack:
				updateAnimState();
				return;
			case Roll(_, _):
				updateAnimState();
				return;
			default:
		}

		animState = Idle;

		// Нажатие мыши
		if (mo.down(Keyboard.keyCode(KeyCode.Left))) {
			animState = Atack;
		} else if (mo.down(Keyboard.keyCode(KeyCode.Right))) {
			animState = Block;
		}
		// Нажатие клавиатуры
		else {
			// Движение вперёд
			if (kb.down(Keyboard.keyCode(KeyCode.W))) {
				// Бег
				if (kb.down(Keyboard.keyCode(KeyCode.Shift))) {
					animState = AnimationState.Run(Forward);
				}
				// Хотьба
				else {
					var side = None;

					// Движение влево и вперёд
					if (kb.down(Keyboard.keyCode(KeyCode.A))) {
						side = Left;
					}
					// Движение вправо и вперёд
					else if (kb.down(Keyboard.keyCode(KeyCode.D))) {
						side = Right;
					}

					animState = AnimationState.Walk(Forward, side);
				}
			}
			// Движение назад
			else if (kb.down(Keyboard.keyCode(KeyCode.S))) {
				var side = None;

				// Движение влево и назад
				if (kb.down(Keyboard.keyCode(KeyCode.A))) {
					side = Left;
				}
				// Движение вправо и назад
				else if (kb.down(Keyboard.keyCode(KeyCode.D))) {
					side = Right;
				}

				animState = AnimationState.Walk(Backward, side);
			}
			// Движение влево
			else if (kb.down(Keyboard.keyCode(KeyCode.A))) {
				animState = AnimationState.Walk(None, Left);
			}
			// Движение вправо
			else if (kb.down(Keyboard.keyCode(KeyCode.D))) {
				animState = AnimationState.Walk(None, Right);
			}
		}

		updateAnimState();
	}

	// Обрабатывает обновление
	function onUpdate() {
		updateInput();

		//camera.buildMatrix();
	}

	// Обрабатывает обновление физики
	function preUpdate() {
		if (Input.occupied || !body.ready)
			return;
	
		var mo = Input.getMouse();
		var kb = iron.system.Input.getKeyboard();
		if (mo.down() && !mo.locked)
			mo.lock();

		if (kb.down(Keyboard.keyCode(KeyCode.Escape)))
			mo.unlock();		

		camera.transform.rotate(zVec, -mo.movementY / 250 * rotationSpeed);
		transform.rotate(zVec, -mo.movementX / 250 * rotationSpeed);		
		body.syncTransform();
	}

	// Конструктор
	public function new() {
		super();

		notifyOnInit(function() {
			#if (arm_physics)
			PhysicsWorld.active.notifyOnPreUpdate(preUpdate);
			#end

			animation = getAnimimation(object);
			body = getRigidBody(object);
			//camera = cast(object.getChildOfType(CameraObject), CameraObject);
			camera = object.getChild("CameraAxis");
			transform = object.transform;
		});

		notifyOnUpdate(onUpdate);

		// notifyOnRemove(function() {
		// });
	}
}
