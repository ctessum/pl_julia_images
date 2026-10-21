# Diagnostic status page: answers on port 1234 with the startup timing log until Pluto takes over.
using Sockets

const log = ENV["PLUTO_STARTUP_LOG"]
server = listen(IPv4(0), 1234)

@async while isopen(server)
    sock = try accept(server) catch; break end
    @async begin
        try
            while !eof(sock) && !isempty(strip(readline(sock))) end  # skip the request headers
            body = "<html><head><meta http-equiv=\"refresh\" content=\"3\"></head><body><h3>Workspace is starting (diagnostic mode)</h3><pre>" *
                   (isfile(log) ? read(log, String) : "") * "</pre></body></html>"
            write(sock, "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: $(sizeof(body))\r\nConnection: close\r\n\r\n", body)
        catch
        end
        close(sock)
    end
end

while !isfile("/tmp/stop_responder")
    sleep(0.1)
end
close(server)
touch("/tmp/responder_closed")
