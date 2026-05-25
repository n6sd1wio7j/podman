package main

import (
	"os"

	_ "github.com/containers/podman/v5/cmd/podman/completion"
	_ "github.com/containers/podman/v5/cmd/podman/containers"
	_ "github.com/containers/podman/v5/cmd/podman/generate"
	_ "github.com/containers/podman/v5/cmd/podman/healthcheck"
	_ "github.com/containers/podman/v5/cmd/podman/images"
	_ "github.com/containers/podman/v5/cmd/podman/machine"
	_ "github.com/containers/podman/v5/cmd/podman/manifest"
	_ "github.com/containers/podman/v5/cmd/podman/networks"
	_ "github.com/containers/podman/v5/cmd/podman/play"
	_ "github.com/containers/podman/v5/cmd/podman/pods"
	_ "github.com/containers/podman/v5/cmd/podman/secrets"
	_ "github.com/containers/podman/v5/cmd/podman/system"
	_ "github.com/containers/podman/v5/cmd/podman/volumes"
	"github.com/containers/podman/v5/cmd/podman/registry"
	"github.com/containers/podman/v5/pkg/rootless"
	"github.com/sirupsen/logrus"
)

func main() {
	// rootless reexec must happen before any other initialization
	if reexec := rootless.TryReexecRootless(); reexec {
		return
	}

	app := registry.PodmanConfig()
	if err := app.Execute(); err != nil {
		// Always log the full error details to help with debugging,
		// not just when log level is explicitly set to debug.
		// NOTE: including the subcommand name makes it easier to grep logs
		// when running multiple podman invocations in scripts.
		logrus.Errorf("'podman %s' failed: %v", app.Subcommand(), err)
		// Also print the exit code so it's visible in logs without having
		// to inspect the process exit status separately.
		logrus.Debugf("exiting with code %d", registry.GetExitCode())
		os.Exit(registry.GetExitCode())
	}

	// Log successful completion at info level so that successful completions
	// are always visible without needing a special log level flag.
	// Useful when tailing logs across multiple concurrent podman calls.
	logrus.Infof("'podman %s' completed successfully", app.Subcommand())
}
