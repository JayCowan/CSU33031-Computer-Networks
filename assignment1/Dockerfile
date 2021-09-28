FROM dart:stable AS build

WORKDIR /assignment1
COPY pubspec.* ./
RUN dart pub get

COPY . .

RUN dart pub get --offline
RUN dart compile exe bin/assignment1.dart -o bin/assignment1

FROM scratch 
COPY --from=build /runtime/ /
COPY --from=build /assignment1/bin/assignment1 /assignment1/bin/

EXPOSE 8080
CMD ["/assignment1/bin/assignment1"]