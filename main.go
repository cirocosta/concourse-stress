package main

import (
	"log"
	"os/exec"
	"strconv"
	"sync"
)

const (
	pipelines = 1
	workers   = 10
	jobs      = 20
)

func runPipeline(name string) {
	unpausePipeline(name)
	defer pausePipeline(name)

	var wg sync.WaitGroup

	for i := 0; i < jobs; i++ {
		wg.Add(1)

		go func() {
			i := i
			triggerJob(name, "test-"+strconv.Itoa(i))
			wg.Done()
		}()
	}

	wg.Wait()
}

func runCommand(c ...string) {
	cmd := exec.Command("fly",
		"--target=local",
	)

	log.Println(c)

	err := cmd.Run()
	if err != nil {
		log.Printf("failed: %+v", c)
	}

}

func pausePipeline(name string) {
	runCommand(
		"pause-pipeline", "-p", name,
	)
}

func unpausePipeline(name string) {
	runCommand(
		"unpause-pipeline", "-p", name,
	)
}

func triggerJob(pipeline, job string) {
	runCommand(
		"trigger-job",
		"-w",
		"-j",
		pipeline+"/"+job,
	)
}

func worker(queue chan int, wg *sync.WaitGroup) {
	for pipelineId := range queue {
		runPipeline("test-" + strconv.Itoa(pipelineId))
		wg.Done()
	}
}

func main() {
	queue := make(chan int, 0)
	var wg sync.WaitGroup

	for i := 0; i < workers; i++ {
		go worker(queue, &wg) // bring up some workers to take work from a queue
	}

	for pipelineId := 0; pipelineId < pipelines; pipelineId++ {
		wg.Add(1)
		queue <- pipelineId
	}

	wg.Wait()
}
