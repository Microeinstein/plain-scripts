#!/usr/bin/env -S bash -c "set -x; tail -n+2 \$0 | clang++ -x c++ -std=c++20 -march=native -Ofast -flto -Wfatal-errors -Wall -Wextra -pedantic - && ./a.out"
// -Ofast -flto   -Og
// C++
#include <iostream>
#include <iomanip>
#include <format>

#include <vector>
#include <iterator>

// C
#include <cstdlib>

// linux
#include <sys/ioctl.h>
#include <unistd.h>


using
    std::string, std::vector, std::format,
    std::cout, std::cerr, std::endl;


inline void concat(string& dest, const vector<string>& v) {
    for (auto e : v) dest += e;
}
inline void concat(string& dest, const vector<char>& v) {
    for (auto e : v) dest += e;
}

inline string concat(const vector<string>& v) {
    string ret;
    concat(ret, v);
    return ret;
}
inline string concat(const vector<char>& v) {
    string ret;
    concat(ret, v);
    return ret;
}

inline string join(string delim, const vector<string>& v) {
    string ret;
    if (v.size() == 0) return ret;
    auto iter = v.begin();
    ret += *iter;
    for (advance(iter, 1); iter != v.end(); ++iter) {
        ret += delim;
        ret += *iter;
    }
    return ret;
}

inline void writelines(std::ostream& out, const vector<string>& v) {
    for (auto s : v) out << s << endl;
}


inline auto get_term_cols() {
    struct winsize w;
    ioctl(0, TIOCGWINSZ, &w);
    return w.ws_col;
}

inline string get_username() {
    return string(cuserid(nullptr));
}

inline string get_workdir() {
    char *raw = get_current_dir_name();
    string ret{raw};
    free(raw);
    return ret;
}

inline bool check_env_def(const char* k) {
    return !!std::getenv(k);
}

inline bool check_env_is(const char* k, const char* v) {
    char *ptr = std::getenv(k);
    if (!ptr) return false;
    return string(ptr) == v;
}


/*
 * https://wiki.archlinux.org/title/Bash/Prompt_customization
 * https://man.archlinux.org/man/bash.1#PROMPTING
 * https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
 * https://superuser.com/a/301355
 *
 *     <PS1>[PS2]<Enter><PS0>[PS3][PS4]
 *     PROMPT_COMMAND can be used, but not for printing;
 *         must use it to save status.
 */

namespace ansi {
    string
        esc   = "\033",
        reset = "0",
        bold  = "1",
        reset_all = esc + "(B" + esc + "[m";

    struct {
        string cust256 = "38;5";
        struct { string
            black  = "30", red   = "31", green   = "32",
            yellow = "33", blue  = "34", magenta = "35",
            cyan   = "36", white = "37";
        } dark;
        struct { string
            black  = "90", red   = "91", green   = "92",
            yellow = "93", blue  = "94", magenta = "95",
            cyan   = "96", white = "97";
        } light;
    } fg;
    
    vector rainbow_dark {
        "196",  "202",  "208",  "214",  "220",  "226",  "190",  "154",  "118",  "82",
        "46",   "47",   "48",   "49",   "50",   "51",   "45",   "39",   "33",   "27",
        "21",   "57",   "93",   "129",  "165",  "201",  "200",  "199",  "198",  "197",
    };
    
    vector rainbow_light {
        "160",  "166",  "172",  "178",  "142",  "106",  "70",   "71",   "72",   "73",
        "74",   "68",   "62",   "56",   "92",   "128",  "164",  "163",  "162",  "161",
    };

    
    inline string fmt(vector<string> list) {
        return concat({esc, "[", join(";", list), "m"});
    }
}

namespace bash {
    constexpr char Q1 = '\'',  Q2 = '"',  ESC = '\\';
    
    namespace ps { string
        a     = "\x01",
        b     = "\x02",
        user  = "\\u",
        cpath = "\\w",
        cdir  = "\\W",
        euid  = "\\$";
    }

    constexpr auto PROMPT_CMD = "PROMPT_COMMAND";

    inline string quote1(string arg) {
        string ret;
        ret += Q1;
        for (char& c : arg) {
            if (c == Q1) concat(ret, {c, ESC, c});
            ret += c;
        }
        ret += Q1;
        return ret;
    }
    inline string quote2(string arg) {
        string ret;
        ret += Q2;
        for (char& c : arg) {
            if (c == Q2) ret += ESC;
            ret += c;
        }
        ret += Q2;
        return ret;
    }
    inline string noprint(string arg) {
        return concat({ps::a, arg, ps::b});
    }
    inline string set(string k, string v) {
        return concat({k, "=", v});
    }
    inline string var_(string v) {
        return "$" + v;
    }
    inline string var(string v) {
        return concat({"\"$", v, "\""});
    }
    inline string subsh(string arg) {
        return concat({"\"$(",  arg,  ")\""});
    }
    inline string cmd(const vector<string>& v) {
        return join(" ", v);
    }
    inline string cmds(const vector<string>& v) {
        return join("; ", v);
    }
    inline string procsub(const vector<string>& v) {
        return concat({"<(",  cmd(v),  ")"});
    }
    inline string func(string name, const vector<string>& v) {
        return concat({name, "() { ", cmds(v), "; }"});
    }
}


constexpr const char* PROMPT_MY = "_prompt_my";
string PROG;


namespace V {
    string user  = get_username();
    string dir   = get_workdir();
    ushort tcols = get_term_cols();
    bool is_root = geteuid() == 0;
    bool is_long = user.length() + dir.length() + 4 > tcols / 2;
    
    bool is_vscode = check_env_is("TERM_PROGRAM", "vscode");
    bool is_jetbr  = check_env_is("TERMINAL_EMULATOR", "JetBrains-JediTerm");
    bool is_kate   = check_env_def("KATE_PID");
    bool is_xterm  = check_env_def("XTERM_VERSION");
    
    bool as_light = is_vscode || is_jetbr;
    bool as_simpl = is_long || is_kate || is_vscode || is_jetbr;
    bool as_rever = is_xterm;
    
    vector<const char*>& rainbow = as_light ? ansi::rainbow_light : ansi::rainbow_dark;
}


namespace E { const char
    *pr = "prompt",
    *re = "resize";
}


using argnames = struct {  // type is pointer to unnamed struct
    char *event;
    char *print_i;
}*;


struct state {
    string event = E::pr;
    int rbow_i = V::is_root ? -1 : (V::as_light ? 6 : 8);
    
    static state read(char *args[]) {
        state r;
        auto a = reinterpret_cast<argnames>(args);
        r.event = string(a->event);
        r.rbow_i = std::stoi(a->print_i);
        return r;
    }
    string write() {
        using namespace bash;
        return func(PROMPT_MY, { cmd({ "source", procsub({
            PROG, "gen",  concat({"\"${1:-", E::pr, "}\""}),  std::to_string(rbow_i)
        }) }) });
    }
};


void shell_gen(char *args[]) {
    using namespace ansi;
    using namespace bash;
    
    auto s = state::read(args);
    if (s.event == E::pr)
        s.rbow_i = (s.rbow_i + 1) % V::rainbow.size();
    
    // cerr << TCOLS << "  " << USER << "  " << DIR << endl;
    
    /* DRAFTS
     *   Resizing
     *     { sleep 2; tput sc; tput khome; tput hpa 0; tput dch1; tput rc; } &
     *   
     *   Get background color
     *     \e]11;?\a  ->  11;rgb:2323/2626/2727  ->  (OR)>7f
     * 
     *   Detect cursor not at column 1
     *   Get last command return code
     *   Print only last 2 parts of current dir
     */
    
    string
        rain  = V::rainbow[s.rbow_i],
        lrain = noprint(fmt({reset, bold, fg.cust256, rain})),
        drain = noprint(fmt({reset, fg.cust256, rain})),
        luser = noprint(fmt({reset, V::is_root ? fg.light.red : fg.light.green})),
        duser = noprint(fmt({reset, V::is_root ? fg.dark.red : fg.dark.green})),
        white = noprint(fmt({reset,
            V::as_light ? ""
                : V::as_rever
                    ? fg.light.black
                    : fg.light.white })),
        gray  = noprint(fmt({reset,
            V::as_light ? ""
                : V::as_rever
                    ? fg.dark.black
                    : fg.dark.white }));
    
    string PS1;
    
    if (V::as_simpl)
        PS1 = concat({gray, ps::cdir, " ",   lrain, ps::euid,   drain, "> ",  white});
    else
        PS1 = concat({
            lrain, ps::user,   white, ") ",   gray, ps::cpath, " ",
            luser, ps::euid,   duser, "> ",   white
        });

    writelines(cout, {
        set("PS1", quote1(PS1)),
        s.write(),
    });
}


void shell_init() {
    using namespace bash;
    state defaults;
    
    writelines(cout, {
        defaults.write(),
        // "trap - SIGWINCH",
        // format("trap '{} resize' SIGWINCH", PROMPT_MY),
        set("PS0", subsh("tput sgr0")),
        V::as_rever ? "printf '\\e[?5h\\e[?30h'" : "",
        format(
            //R"([[ "${{{0}[*]}}" =~ .*\ ?{1}[\ \;].* ]] || {0}+=('{1}'))",
            R"([[ "${{{0}[*]}}" == *{1}* ]] || {0}+=('{1}'))",
            PROMPT_CMD, PROMPT_MY
        ),
    });
}


void print_help() {
    using namespace ansi;
    cerr << format(1 + R"h(
Usage: {0} <args..>

Arguments:
    help, --help, -h    Show this message.
    init                Print shell script to be evaluated.
    gen <state..>       Run at {1}.

Load with {3}source <({0} init){2} in your {3}~/.bashrc{2}.
)h", PROG, bash::PROMPT_CMD, reset_all, fmt({fg.light.magenta}));
}


int main(int argc, char *argv[]) {  // $0 <cmd>
    PROG = argv[0];
    if (argc <= 1)
        return print_help(), 1;

    string arg = argv[1];
    
    if (arg == "help" || arg == "--help" || arg == "-h")
        return print_help(), 0;
    if (arg == "init")
        return shell_init(), 0;
    if (arg == "gen")
        return shell_gen(&argv[2]), 0;

    cerr << "Unknown argument: " << arg << endl;
    return print_help(), 1;
}

