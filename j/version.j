## semantic version numbers (http://semver.org)

type VersionNumber
    major::Int16
    minor::Int16
    patch::Int16
    suffix::String

    function VersionNumber(major::Integer, minor::Integer, patch::Integer, suffix::String)
        if major < 0; error("invalid major version: $major"); end
        if minor < 0; error("invalid minor version: $minor"); end
        if patch < 0; error("invalid patch version: $patch"); end
        if !matches(ri"^(?:[a-z-][0-9a-z-]*)?$", suffix)
            error("invalid version suffix: $suffix")
        end
        new(int16(major), int16(minor), int16(patch), suffix)
    end
end
VersionNumber(x::Integer, y::Integer, s::String) = VersionNumber(x, y, 0, s )
VersionNumber(x::Integer, s::String)         = VersionNumber(x, 0, 0, s )
VersionNumber(x::Integer, y::Integer, z::Integer)    = VersionNumber(x, y, z, "")
VersionNumber(x::Integer, y::Integer)            = VersionNumber(x, y, 0, "")
VersionNumber(x::Integer)                    = VersionNumber(x, 0, 0, "")

print(v::VersionNumber) = print("$(v.major).$(v.minor).$(v.patch)$(v.suffix)")
show(v::VersionNumber) = print("v\"", v, "\"")

convert(::Type{VersionNumber}, v::Integer) = VersionNumber(v)
convert(::Type{VersionNumber}, v::Tuple) = VersionNumber(v...)

const VERSION_REGEX = ri"^v?(\d+)(?:\.(\d+)(?:\.(\d+))?)?((?:[a-z-][0-9a-z-]*)?)$"

function convert(::Type{VersionNumber}, v::String)
    m = match(VERSION_REGEX, v)
    if m == nothing; error("invalid version string: $v"); end
    major, minor, patch, suffix = m.captures
    major = parse_dec(major)
    minor = minor == nothing ? 0 : parse_dec(minor)
    patch = patch == nothing ? 0 : parse_dec(patch)
    VersionNumber(major, minor, patch, suffix)
end

macro v_str(v); convert(VersionNumber, v); end

<(a::VersionNumber, b::VersionNumber) =
    a.major < b.major || a.major == b.major &&
    (a.minor < b.minor || a.minor == b.minor &&
     (a.patch < b.patch || a.patch == b.patch &&
      (!isempty(a.suffix) && (isempty(b.suffix) || a.suffix < b.suffix))))

==(a::VersionNumber, b::VersionNumber) =
    a.major == b.major && a.minor == b.minor &&
    a.patch == b.patch && a.suffix == b.suffix

<(a::VersionNumber, b) = a < convert(VersionNumber,b)
<(a, b::VersionNumber) = convert(VersionNumber,a) < b
==(a::VersionNumber, b) = a == convert(VersionNumber,b)
==(a, b::VersionNumber) = convert(VersionNumber,a) == b

## julia version info

const VERSION = convert(VersionNumber,readall(`cat $JULIA_HOME/VERSION`)[1:end-1])
const VERSION_COMMIT = readall(`git rev-parse HEAD`)[1:end-1]
const VERSION_CLEAN = success(`git diff --quiet`)
const VERSION_TIME = readall(
    `git log -1 --pretty=format:%ct` |
    `perl -MPOSIX=strftime -e 'print strftime "%F %T", gmtime <>'`
)

begin

const _jl_version_string = "Version $VERSION"
local _jl_version_clean = VERSION_CLEAN ? "" : "*"
const _jl_commit_string = "Commit $(VERSION_COMMIT[1:10]) ($VERSION_TIME)$_jl_version_clean"

const _jl_banner_plain =
I"               _
   _       _ _(_)_     |
  (_)     | (_) (_)    |  A fresh approach to technical computing
   _ _   _| |_  __ _   |
  | | | | | | |/ _` |  |  $_jl_version_string
  | | |_| | | | (_| |  |  $_jl_commit_string
 _/ |\__'_|_|_|\__'_|  |
|__/                   |

"

local tx = "\033[0m\033[1m" # text
local _jl = "\033[0m\033[1m" # julia
local d1 = "\033[34m" # first dot
local d2 = "\033[31m" # second dot
local d3 = "\033[32m" # third dot
local d4 = "\033[35m" # fourth dot
const _jl_banner_color =
"\033[1m               $(d3)_
   $(d1)_       $(_jl)_$(tx) $(d2)_$(d3)(_)$(d4)_$(tx)     |
  $(d1)(_)$(_jl)     | $(d2)(_)$(tx) $(d4)(_)$(tx)    |  A fresh approach to technical computing
   $(_jl)_ _   _| |_  __ _$(tx)   |
  $(_jl)| | | | | | |/ _` |$(tx)  |  $_jl_version_string
  $(_jl)| | |_| | | | (_| |$(tx)  |  $_jl_commit_string
 $(_jl)_/ |\\__'_|_|_|\\__'_|$(tx)  |
$(_jl)|__/$(tx)                   |

\033[0m"

_jl_color_available() =
    success(`tput setaf 0`) || has(ENV, "TERM") && matches(r"^xterm", ENV["TERM"])

_jl_banner() = print(_jl_color_available() ? _jl_banner_color : _jl_banner_plain)

end # begin
