#! /bin/env Rscript

## Run this after running the 'grab-results.sh' script which gathers
## the CSV files requried.  This script will create 3 files matching
## 'graph-*.svg' which are plots of the results.
##
## I use .svg format for the output, I tried .png, but the text looks
## horrible, it's much nicer in the .svg.

riscv_data <- read.csv ("riscv-nolibc-nolibgcc-nolibm.csv", header=FALSE)
arm_data <- read.csv ("arm-nolibc-nolibgcc-nolibm.csv", header=FALSE)
arc_data <- read.csv ("arc-nolibc-nolibgcc-nolibm.csv", header=FALSE)

colnames (riscv_data) <- c("Benchmark", "Text", "Data", "BSS")
colnames (arm_data) <- c("Benchmark", "Text", "Data", "BSS")
colnames (arc_data) <- c("Benchmark", "Text", "Data", "BSS")

riscv_data$Arch <- "RISC-V"
arm_data$Arch <- "ARM"
arc_data$Arch <- "ARC"

all_data <- rbind (riscv_data, arm_data, arc_data)

library ("ggplot2")
library ("reshape2")
library ("scales")
library ("grid")

g1 <- ggplot (all_data, aes (Benchmark, Text, fill=Arch)) +
            geom_col (position=position_dodge ()) +
            theme(axis.text.x = element_text(angle = 90, vjust=0.5, hjust = 1)) +
            theme(plot.title = element_text(hjust = 0.5)) +
            ggtitle ("Size Of All Text Sections For Expanded BEEBS Set") +
            xlab ("Benchmark Name") + ylab ("Size Of Text Sections In Bytes") +
            scale_fill_discrete(name="Architecture")


inc_data <- data.frame(Benchmark = riscv_data$Benchmark)
inc_data$ARM_to_RISCV = 100.0 * (riscv_data$Text - arm_data$Text) / arm_data$Text
inc_data$ARC_to_RISCV = 100.0 * (riscv_data$Text - arc_data$Text) / arc_data$Text
inc_data <- melt(inc_data, id=c("Benchmark"))

g2 <- ggplot (inc_data, aes (Benchmark, value, fill=variable)) +
            geom_col (position=position_dodge ()) +
            scale_y_continuous(breaks=pretty_breaks(n=10)) +
            theme(axis.text.x = element_text(angle = 90, vjust=0.5, hjust = 1)) +
            theme(plot.title = element_text(hjust = 0.5)) +
            ggtitle ("Percentage Increase From ARM/ARC to RISC-V For Expanded BEEBS Set") +
            xlab ("Benchmark Name") + ylab ("Percentage Increase / Decrease") +
            scale_fill_discrete(name="Increase From\nBase Architecture\nTo RISC-V",
                         breaks=c("ARC_to_RISCV", "ARM_to_RISCV"),
                         labels=c("ARC to RISC-V", "ARM to RISC-V"))

## Like 'g1' but with the x-axis decoration removed.
g3 <- g1 + theme(axis.title.x=element_blank(),
                 axis.text.x=element_blank(),
                 axis.ticks.x=element_blank())

##
## Generate the graphs.
##

svg (filename="graph-absolute-sizes.svg", width=20, height=10)
print (g1)
invisible (dev.off ())

svg (filename="graph-relative-sizes.svg", width=20, height=10)
print (g2)
invisible (dev.off ())

svg (filename="graph-combined-sizes.svg", width=20, height=10)
grid.newpage()
grid.draw(rbind(ggplotGrob(g3), ggplotGrob(g2), size = "last"))
invisible (dev.off ())
