#include <QDir>
#include <QDebug>
#include <QJsonArray>
#include <QQmlContext>
#include <QJsonObject>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QJsonDocument>
#include <QGuiApplication>
#include <QRegularExpression>
#include <QQmlApplicationEngine>

#ifdef Q_OS_ANDROID
#include "android/JavaToCppBind.h"
#include "android/cpp/androidgallery.h"
#endif
#include "cpp/pushnotificationtokenlistener.h"

QJsonArray loadPlugins()
{
    QFile pluginsQrc(":/plugins.qrc");
    QRegularExpression regexp("alias=\"(.*\\.json)?\"");
    QJsonArray crudArray;
    QJsonParseError error;
    if (pluginsQrc.open(QIODevice::ReadOnly)) {
        QTextStream in(&pluginsQrc);
        while (!in.atEnd()) {
            QRegularExpressionMatch match = regexp.match(in.readLine());
            if (match.hasMatch()) {
                QFile configJson(":/plugins/" + match.captured(1));
                if (configJson.open(QIODevice::ReadOnly)) {
                    QJsonObject jsonObject = QJsonDocument::fromJson(configJson.readAll(), &error).object();
                    jsonObject["root_folder"] = "/plugins/" + match.captured(1).split('/').first();
                    crudArray << jsonObject;
                }
            }
        }
    }
    pluginsQrc.close();
    return crudArray;
}

QVariantMap loadAppConfig()
{
    QFile file;
    file.setFileName(":/settings.json");
    file.open(QIODevice::ReadOnly | QIODevice::Text);
    QString settings(file.readAll());
    file.close();
    QJsonDocument jsonDocument = QJsonDocument::fromJson(settings.toUtf8());
    return jsonDocument.object().toVariantMap();
}

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QQuickStyle::setStyle("Material");
    QGuiApplication app(argc, argv);

    QVariantMap settings(loadAppConfig());
    settings.insert("theme", settings.value("theme").toMap().value("material").toMap());

    QQmlApplicationEngine engine;
    QQmlContext *context = engine.rootContext();
    context->setContextProperty("appSettings", settings);
    context->setContextProperty("crudModel", QVariant::fromValue(loadPlugins()));

    #ifdef Q_OS_ANDROID
        AndroidGallery androidgallery;
        context->setContextProperty("androidGallery", &androidgallery);
    #endif

    PushNotificationTokenListener pushNotificationTokenListener;

    engine.load(QUrl(QLatin1String("qrc:/qml/Main.qml")));

    QQuickWindow *window = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0));
    QObject::connect(&pushNotificationTokenListener, SIGNAL(tokenUpdated(QVariant)), window, SLOT(registerPushNotificationToken(QVariant)));

    return app.exec();
}
