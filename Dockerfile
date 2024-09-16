FROM ubuntu:20.04 as builder

RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone

RUN DEBIAN_FRONTEND=noninteractive \
	apt-get update && apt-get install -y build-essential tzdata pkg-config \
	wget clang git

RUN wget https://go.dev/dl/go1.19.1.linux-amd64.tar.gz
RUN rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

ADD . /viper
WORKDIR /viper
ADD fuzzers/fuzz_setdefault.go ./fuzzers/
WORKDIR ./fuzzers/
RUN go install github.com/dvyukov/go-fuzz/go-fuzz@latest github.com/dvyukov/go-fuzz/go-fuzz-build@latest
RUN go get github.com/dvyukov/go-fuzz/go-fuzz-dep
RUN go get github.com/spf13/viper
RUN /root/go/bin/go-fuzz-build -libfuzzer -o harness.a
# Generate harness binary
RUN clang -fsanitize=fuzzer harness.a -o fuzz_setdefault

FROM ubuntu:20.04
COPY --from=builder /viper/fuzzers/fuzz_setdefault /

ENTRYPOINT []
CMD ["/fuzz_setdefault"]
