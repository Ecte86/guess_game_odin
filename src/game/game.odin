package game

import "core:fmt"

// import a random number generator
import "core:math/rand"

// import the operating system module for stdin and stdout
import "core:os"

// import the strconv module for parsing integers
import "core:strconv"

// import the strings module for string manipulation
import "core:strings"

GameState :: enum {
	PLAYING,
	WON,
	LOST,
}

Game :: struct {
	max_guesses:   i32,
	current_guess: i32,
	last_guess:    i32,
	state:         GameState,
	secret_number: i32,
	num_guesses:   i32,
}

Result :: struct {
	success: bool,
	message: string,
}

new_game :: proc(max_guesses: i32) -> Game {
	g := Game{}
	g.secret_number = generate_secret_number(1, 100)
	g.num_guesses = 1
	g.max_guesses = max_guesses
	g.current_guess = 0
	g.last_guess = 0
	g.state = GameState.PLAYING
	return g
}

generate_secret_number :: proc(min: i32, max: i32) -> i32 {
	return random_range(min, max)
}

random_range :: proc(min: i32, max: i32) -> i32 {
	num := rand.int_max(int(max)) + int(min)
	return i32(num)
}

game_run :: proc() -> Result {
	game := new_game(10)
	result := game_loop(&game)

	if result.success {
		return Result{success = result.success, message = result.message}
	} else {
		return Result{success = false, message = "An error occurred"}
	}
}

game_loop :: proc(game: ^Game) -> Result {
	for game.state == GameState.PLAYING {
		//fmt.eprintf("Secret number: %d\n", game.secret_number)
		fmt.printfln("Guess #%d of %d", game.num_guesses, game.max_guesses)
		fmt.print("Enter your guess: ")
		guess_result := get_guess(game)
		if !guess_result.success {
			if game.current_guess == 0 {
				fmt.println(guess_result.message)
				continue
			}
			if guess_result.message == "" {
				return Result{success = false, message = "An error occurred getting the guess"}
			}
			fmt.eprintf("Error: %s\n", guess_result.message)
		}
		game.state = check_guess(game)
	}

	if game.state == GameState.WON {
		return Result{success = true, message = "You won!"}
	} else {
		return Result{success = true, message = "You lost!"}
	}
}

get_guess :: proc(game: ^Game) -> Result {
	buf := [10]u8{}
	_, err_read := os.read(os.stdin, buf[:])
	if err_read != nil {
		game.current_guess = -1
		return Result{success = false, message = "An error occurred reading input"}
	}
	guess, ok_parse := strconv.parse_int(string(buf[:]))
	if ok_parse != false {
		game.current_guess = -1
		return Result{success = false, message = "An error occurred parsing input"}
	}
	if guess < 1 || guess > 100 {
		return Result{success = false, message = "Guess must be between 1 and 100"}
	}
	guess_i32 := i32(guess)
	game.last_guess = game.current_guess
	game.current_guess = guess_i32
	return Result{success = true, message = ""}
}

check_guess :: proc(game: ^Game) -> GameState {
    if game.num_guesses >= game.max_guesses {
		fmt.printfln("You ran out of guesses! The secret number was %d", game.secret_number)
		return GameState.LOST
	}
	if game.current_guess == game.secret_number {
		fmt.printfln("You guessed the secret number in %d tries!", game.num_guesses)
		return GameState.WON
	}
	if game.current_guess < game.secret_number {
		fmt.print("Too low!\n")
	} else {
		fmt.print("Too high!\n")
	}
	game.num_guesses += 1

	return GameState.PLAYING
}
