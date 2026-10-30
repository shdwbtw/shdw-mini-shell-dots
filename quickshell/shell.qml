//@ pragma UseQApplication
import Quickshell
import qs.island
import qs.controlcenter
import qs.lock

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Variants {
        model: Quickshell.screens

        Island {}
    }

    Variants {
        model: Quickshell.screens

        ControlCenter {}
    }

    LockScreen {}
}
