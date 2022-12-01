FROM golang:1.16-alpine AS builder

WORKDIR /app

COPY flashcards-gsheet-go ./

RUN go mod download


RUN CGO_ENABLED=0 go build -o /flashcards-gsheet

FROM gcr.io/distroless/base-debian10 AS runner

WORKDIR /

COPY --from=builder /flashcards-gsheet /flashcards-gsheet

EXPOSE 8090

USER nonroot:nonroot

ENTRYPOINT ["/flashcards-gsheet"]