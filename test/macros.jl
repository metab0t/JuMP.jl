# macros.jl
# Tests for macros

# Check for changes in Julia's expression parsing
sumexpr = :(sum{x[i,j] * y[i,j], i = 1:N, j = 1:M; i != j})
if VERSION >= v"0.3.0-"
    @test string(sumexpr) == ":(sum{Expr(:parameters, :(i != j)),x[i,j] * y[i,j],i = 1:N,j = 1:M})"
end
@test sumexpr.head == :curly
@test length(sumexpr.args) == 5
@test sumexpr.args[1] == :sum
@test sumexpr.args[2].head == :parameters
@test sumexpr.args[3] == :(x[i,j] * y[i,j])
@test sumexpr.args[4].head == :(=)
@test sumexpr.args[5].head == :(=)


sumexpr = :(sum{x[i,j] * y[i,j], i = 1:N, j = 1:M})
if VERSION >= v"0.3.0-"
    @test string(sumexpr) == ":(sum{x[i,j] * y[i,j],i = 1:N,j = 1:M})"
end
@test sumexpr.head == :curly
@test length(sumexpr.args) == 4
@test sumexpr.args[1] == :sum
@test sumexpr.args[2] == :(x[i,j] * y[i,j])
@test sumexpr.args[3].head == :(=)
@test sumexpr.args[4].head == :(=)

# test JuMP's macros

let 
    m = Model()
    @defVar(m, w)
    @defVar(m, x)
    @defVar(m, y)
    @defVar(m, z)
    t = 10

    @addConstraint(m, 3x - y == 3.3(w + 2z) + 5) 
    @test conToStr(m.linconstr[end]) == "3.0 x - 1.0 y - 3.3 w - 6.6 z == 5.0"
    @addConstraint(m, (x+y)/2 == 1) 
    @test conToStr(m.linconstr[end]) == "0.5 x + 0.5 y == 1.0"
    @addConstraint(m, -1 <= x-y <= t) 
    @test conToStr(m.linconstr[end]) == "-1.0 <= 1.0 x - 1.0 y <= 10.0"
    @addConstraint(m, -1 <= x+1 <= 1)
    @test conToStr(m.linconstr[end]) == "-2.0 <= 1.0 x <= 0.0"
    @test_throws @addConstraint(m, x <= t <= y)
end

let
    m = Model()
    @defVar(m, x[1:3,1:3])
    @defVar(m, y)
    C = [1 2 3; 4 5 6; 7 8 9]
    @addConstraint(m, sum{ C[i,j]*x[i,j], i = 1:2, j = 2:3 } <= 1)
    @test conToStr(m.linconstr[end]) == "2.0 x[1,2] + 3.0 x[1,3] + 5.0 x[2,2] + 6.0 x[2,3] <= 1.0"
    @addConstraint(m, sum{ C[i,j]*x[i,j], i = 1:3, j = 1:3; i != j} == y)
    @test conToStr(m.linconstr[end]) == "2.0 x[1,2] + 3.0 x[1,3] + 4.0 x[2,1] + 6.0 x[2,3] + 7.0 x[3,1] + 8.0 x[3,2] - 1.0 y == 0.0"

    @addConstraint(m, sum{ C[i,j]*x[i,j], i = 1:3, j = 1:i} == 0);
    @test conToStr(m.linconstr[end]) == "1.0 x[1,1] + 4.0 x[2,1] + 5.0 x[2,2] + 7.0 x[3,1] + 8.0 x[3,2] + 9.0 x[3,3] == 0.0"
end

let
    m = Model()
    @defVar(m, x[1:3,1:3])
    C = [1 2 3; 4 5 6; 7 8 9]
    con = @addConstraint(m, sum{ C[i,j]*x[i,j], i = 1:3, j = 1:3; i != j} == 0)
    @test conToStr(m.linconstr[end]) == "2.0 x[1,2] + 3.0 x[1,3] + 4.0 x[2,1] + 6.0 x[2,3] + 7.0 x[3,1] + 8.0 x[3,2] == 0.0"

    @defVar(m, y, 0, [con], [-1.0])
    @test conToStr(m.linconstr[end]) == "2.0 x[1,2] + 3.0 x[1,3] + 4.0 x[2,1] + 6.0 x[2,3] + 7.0 x[3,1] + 8.0 x[3,2] - 1.0 y == 0.0"

    chgConstrRHS(con, 3)
    @test conToStr(m.linconstr[end]) == "2.0 x[1,2] + 3.0 x[1,3] + 4.0 x[2,1] + 6.0 x[2,3] + 7.0 x[3,1] + 8.0 x[3,2] - 1.0 y == 3.0"
end

let
    m = Model()
    @defVar(m, x)
    @defVar(m, y)
    temp = x + 2y + 1
    @addConstraint(m, 3*temp - x - 2 >= 0)
    @test conToStr(m.linconstr[end]) == "6.0 y + 2.0 x >= -1.0"
end

# test ranges in @defVar
let
    m = Model()
    @defVar(m, x[1:5])
    @defVar(m, y[3:2:9])
    @defVar(m, z[4:3:8])
    @defVar(m, w[6:5])

    @test length(x) == 5
    @test length(y) == 4
    @test length(z) == 2
    @test length(w) == 0

    @test x[end].col == x[5].col
    @test y[3].m == y[5].m == y[7].m == y[9].m # just make sure indexing works alright
    @test_throws z[8].col
    @test_throws w[end]

end
