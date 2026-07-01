comptime {
    @compileError(
        "Unable to detect Slurm version\n\r" ++
        "Either provide the slurm install dir via --search-prefix <DIR>\n\r" ++
        "Or specify the Target Slurm version directly by setting the 'version' build option to something like 25.11\n\r"
    );
}
