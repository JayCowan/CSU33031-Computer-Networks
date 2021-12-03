FROM dart:stable AS build

WORKDIR /assignment2
COPY pubspec.* ./
RUN dart pub get

COPY . .

RUN dart pub get --offline
RUN dart compile exe bin/assignment2.dart -o bin/assignment2

FROM scratch 
COPY --from=build /runtime/ /
COPY --from=build /assignment2/bin/assignment2 /assignment2/bin/

EXPOSE 51510/udp
ENTRYPOINT [ "/assignment2/bin/assignment2" ]